# Beets-Docker

Beets-docker is a docker file that includes the
[beets](https://beets.readthedocs.io/en/stable/) music organizer, and
dependencies for a select few plugins. It provides a packaged environment for
the dependencies that beets relies on. And it includes an entrypoint script
allowing to run beets commands directly, or to monitor a directory for new files
to automatically import.

## Usage

### Docker Run

```sh
docker run --rm \
  -v /path/to/config:/config \
  -v /path/to/inbox:/import \
  -e IMPORT_DIR=/import \
  ghcr.io/nedra1998/beets:latest
```

### docker-compose

```yaml
services:
  beets:
    image: ghcr.io/nedra1998/beets:latest
    container_name: beets
    restart: unless-stopped
    user: 1000:1000
    environment:
      - IMPORT_DIR=/import
    volumes:
      - ./config:/config
      - /path/to/library:/library
      - /path/to/import:/import
```

## Configuration

### Environment Variables

| Name | Description | Default |
| --- | --- | --- |
| `CONFIG_FILE` | path to the Beets configuration file. | `/config/config.yaml` |
| `TRIGGER_FILE` | Path to a trigger file that, when modified, triggers an in-place import from `LIBRARY_DIR`. | _not set_ |
| `LIBRARY_DIR` | Directory to import from when trigger file is modified. | `/library` |
| `IMPORT_DIR` | Directory to monitor for new files. When files are added, they are automatically imported after the debounce period.  | _not set_ |
| `DEBOUNCE_SECONDS` | The number of seconds to wait for file activity to stop before importing from `IMPORT_DIR`. | `15` |

### Volume Mounts

| Mount Point | Description |
| --- | --- |
| `/config` | **Required** The Beets configuration directory. Should contain `config.yaml`. |
| `/library` | **Required** The directory of the music within the beets library. |
| `/import` | **Optional** The directory to monitor for new files to import. |

### Modes of Operation

This docker container can operate in several modes depending on the environment
and the arguments provided. The trigger file monitoring and import directory
monitoring can be used together, and both will run concurrently.

#### Command Mode

If you pass arguments to the container, it will execute that Beets command and
exit, acting as a containerized Beets CLI.

```sh
docker run --rm -v ./config:/config -v ./library:/library \
  ghcr.io/nedra1998/beets:latest list artist:Beatles
```

#### Trigger File Monitoring

When the `TRIGGER_FILE` and `LIBRARY_DIR` environment variables are set, the
container runs a monitor that watches the trigger file for modifications. When
the file is modified, it will import new music from the `LIBRARY_DIR`. This is
done with an -in-place import (using `--nocopy`) which means the files are
scanned and tagged but not moved from their current location. This is useful
when an external system manages the files, and beets is only used for tagging,
you can use this mode to trigger beets to re-scan the library when files are
added.

#### Import Directory Monitoring

When the `IMPORT_DIR` environment variable is set, the container runs a monitor
on that directory. When new files are added to the directory, after a debounce
interval to ensure file activity has stopped, the container will import the new
files into the beets library. This is useful for automatically importing new
music you can drop files into the import directory and have them automatically
added to your beets library.

### Beets Plugins Included

Some beets plugins require additional system dependencies to function. This
container pre-installs the dependencies for the following plugins:

- **chroma**: Acoustic fingerprinting for accurate identification
- **embedart**: Embed album art into music files
- **fetchart**: Fetch album art from various sources
- **lastgenre**: Fetch genres from Last.fm
- **lyrics**: Fetch song lyrics
- **replaygain**: Calculate and apply ReplayGain for consistent volume
- **beetcamp**: Bandcamp integration
- **beets-copyartifacts3**: Copy additional files alongside music
