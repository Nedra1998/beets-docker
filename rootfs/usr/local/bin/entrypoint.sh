#!/bin/bash
# @file entrypoint.sh
# @brief Entrypoint script for the Beets docker container.
# @description
# The tnrypoint script supports the main mode of operation for the docker
# container, and handles monitoring for file changes in order to trigger beets
# imports. It also supports running arbitrary beet commands directly, by providing
# arguments to the container.
#
# The configuration for the entrypoint script is done via environment
# variables, which control the two main modes of operation (which can be used
# at the same time):
#
# **Trigger file monitoring**: If the `TRIGGER_FILE` environment variable is
# set, it will monitor that file for modifications using inotify. When the file
# is modified, it will run `beet import` on the specified LIBRARY_DIR. This is
# is useful for triggering imports from external processes by simply touching
# the trigger file. And it will do an in-place import not moving any files,
# especially useful for files that are managed by a download manager or
# similar.
#
# **Import directory monitoring**: If the `IMPORT_DIR` environment variable is
# set, it will monitor that directory for new or modified files using inotify.
# When changes are detected, it will wait for a debounce period of inactivity
# set by `DEBOUNCE_SECONDS` before running `beet import` on the directory. This
# is useful for automatically importing new music files into your beets library
# as they are added, either manually or automatically to the import directory.


TRIGGER_FILE="${TRIGGER_FILE:-}"
LIBRARY_DIR="${LIBRARY_DIR:-/library}"
IMPORT_DIR="${IMPORT_DIR:-}"
DEBOUNCE_SECONDS="${DEBOUNCE_SECONDS:-15}"
CONFIG_FILE="${CONFIG_FILE:-/config/config.yaml}"

LOCK_DIR="/tmp/beets_import.lock"

# @description Log a message with a timestamp.
#
# @arg $1 Log level (e.g., TRC, DBG, INF, WRN, ERR, FTL).
# @arg $2 Log message.
#
# @stderr The log message is printed to standard error, with the current date
# and time.
log() {
  printf "%s %s %s\n" "$(date +%Y-%m-%dT%H:%M:%S)" "$1" "$2" >&2
}

# @description Acquire a POSIX atomic lock using mkdir.
# The lock is represented by a directory. If the lock directory exists,
# then the lock is held by another process, and this function will wait
# until it can acquire the lock.
#
# **Warning**: This function will block indefinitely until the lock is
# acquired, always remember to release the lock after acquiring it, even
# in error conditions.
acquire_lock() {
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        sleep 1
    done
}


# @description Release the POSIX atomic lock.
release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null
}

# @description Monitor the trigger file for modifications and run beets import
# on the `LIBRARY_DIR` when it changes.
monitor_trigger_file() {
  log INF "Starting trigger file watcher on '$TRIGGER_FILE' for import from '$LIBRARY_DIR'."

  inotifywait -m -e close_write --format '%w%f' "$TRIGGER_FILE" | while read -r FILE; do
    log DBG "Trigger file '$FILE' modified, running import on '$LIBRARY_DIR'."
    acquire_lock
    beet -c "${CONFIG_FILE}" import --quiet --nocopy "$LIBRARY_DIR"
    release_lock
    log INF "Import completed for '$LIBRARY_DIR'. Returning to watch mode."
  done
}

# @description Monitor the import directory for new or modified files and run
# beets import after a debounce period of inactivity. The debounce period is
# a period of time during which no new file events are detected, after which
# the import is triggered. This is to prevent multiple imports from being triggered
# while files are still being added.
monitor_import_directory() {
  log INF "Starting import directory watcher on '$IMPORT_DIR' with debounce of ${DEBOUNCE_SECONDS}s."

  # TODO: Currently depends on bash process substitution, would be better to avoid
  # the dependency for better portability, and only use POSIX features.
  exec 3< <(inotifywait -m -r -e create,modify,move,moved_to,close_write --format '%w%f' "$IMPORT_DIR")

  while read -r EVENT <&3; do
    log DBG "Event detected '$EVENT', waiting for debounce period of ${DEBOUNCE_SECONDS}s."

    # Wait for the debounce period
    # TODO: Currently this depends on bash-specific features, would be better to avoid
    # and only use POSIX features for better portability.
    while read -r -t "$DEBOUNCE_SECONDS" EVENT <&3; do
      log DBG "Additional event detected '$EVENT', resetting debounce timer."
      true
    done

    acquire_lock
    beet -c "${CONFIG_FILE}" import --quiet "$IMPORT_DIR"
    release_lock
    log INF "Import completed for '$IMPORT_DIR'. Returning to watch mode."
  done
}

# @description Cleanup function to stop monitors and exit gracefully.
# This is the callback for the trap on termination signals which the container
# will receive when stopping the docker container.
cleanup() {
  log INF "Stopping monitors and exiting..."
  # Kill all background jobs (the watcher loops)
  kill $(jobs -p) 2>/dev/null
  release_lock
  exit 0
}

# Trap TERM and INT signals
trap cleanup TERM INT

if [ $# -gt 0 ]; then
  exec beet -c "${CONFIG_FILE}" "$@"
  exit $?
fi

if [ -n "$TRIGGER_FILE" ]; then
  monitor_trigger_file &
fi

if [ -n "$IMPORT_DIR" ]; then
  monitor_import_directory &
fi

wait
