#!/bin/bash

# Set the default configuration file
if [ ! -d "/config" ]; then
  mkdir -p "/config"
fi

if [ -w /config ] && [ ! -f /config/config.yaml ]; then
  cp /etc/default/beets_config.yaml /config/config.yaml
fi

beets_config="/config/config.yaml"

inotifywait -m -e created,moved_to --format '%w%f' "$WATCH_DIR" | while IFS= read -r dir_path; do
  # Wait for file to be completely written...
  sleep 15

  # Unzip zip files into new subdirectories
  if [ -f "$dir_path" ]; then
    if [[ "$dir_path" == *.zip ]]; then
      unzip -d "${dir_path%.*}" "$dir_path"
      rm "$dir_path"

      continue
    fi
  fi

  # Import music files
  /usr/bin/beet -c "$beets_config" import --incremental --flat "$dir_path"
done

exit 1
