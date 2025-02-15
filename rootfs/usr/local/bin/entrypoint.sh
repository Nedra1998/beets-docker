#!/bin/bash

# Set the default configuration file
if [ ! -d "/config" ]; then
  mkdir -p "/config"
fi

if [ -w /config ] && [ ! -f /config/config.yaml ]; then
  cp /etc/default/beets_config.yaml /config/config.yaml
fi

beets_config="/config/config.yaml"

inotifywait -m -e create,moved_to --format '%w%f' "$WATCH_DIR" | while IFS= read -r dir_path; do
  sleep 1
  # Wait for file to be completely written...
  if [ -f "$dir_path" ]; then
    # Wait for file to be completely written by checking for size changes
    last_size=$(stat -c%s "$dir_path")
    sleep 1
    while [ "$last_size" -ne "$(stat -c%s "$dir_path")" ]; do
      last_size=$(stat -c%s "$dir_path")
      sleep 1
    done
  elif [ -d "$dir_path" ]; then
    # Wait for directory to be completely written by checking for new files
    last_count=$(find "$dir_path" -type f | wc -l)
    sleep 1
    while [ "$last_count" -ne "$(find "$dir_path" -type f | wc -l)" ]; do
      last_count=$(find "$dir_path" -type f | wc -l)
      sleep 1
    done
  fi

  # Unzip zip files into new subdirectories
  if [ -f "$dir_path" ]; then
    if [[ "$dir_path" == *.zip ]]; then
      unzip -d "${dir_path%.*}" "$dir_path"
      rm "$dir_path"

      continue
    fi
  fi

  sleep 1

  # Import music files
  /usr/bin/beet -c "$beets_config" import --incremental --flat "$dir_path"
done

exit 1
