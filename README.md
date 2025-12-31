# Beets Docker Container

A Docker container for [Beets](https://beets.io), the media library management system for obsessive music geeks. This container provides an automated way to run Beets with support for automatic imports through file monitoring.

## What is Beets?

Beets is the media library management system for obsessive music geeks. It catalogs your collection, automatically improving its metadata as it goes. It then provides a variety of tools for manipulating and accessing your music.

## Features

This Docker container includes:
- **Beets** with plugins: chroma, embedart, fetchart, lastgenre, lyrics, replaygain
- **Additional plugins**: beetcamp, beets-copyartifacts3
- **Automatic import monitoring** with two modes:
  - Trigger file monitoring for on-demand imports
  - Import directory monitoring for automatic imports
- **All necessary dependencies** for audio processing and metadata fetching

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BEETSDIR` | `/config` | Directory where Beets configuration and database are stored |
| `CONFIG_FILE` | `/config/config.yaml` | Path to the Beets configuration file |
| `TRIGGER_FILE` | _(not set)_ | Path to a trigger file that, when modified, triggers an in-place import from `LIBRARY_DIR`. Useful for external process triggers. |
| `LIBRARY_DIR` | `/library` | Directory to import from when trigger file is modified (used with `TRIGGER_FILE`) |
| `IMPORT_DIR` | _(not set)_ | Directory to monitor for new files. When files are added, they are automatically imported after the debounce period. |
| `DEBOUNCE_SECONDS` | `15` | Number of seconds to wait for file activity to stop before triggering import (used with `IMPORT_DIR`) |

### Volume Mounts

You should mount the following directories:

| Mount Point | Purpose |
|-------------|---------|
| `/config` | Beets configuration directory (contains `config.yaml` and `library.db`) |
| `/library` | Your music library (where Beets manages your organized music collection) |
| `/downloads` or `/import` | Directory for new music to import (optional, based on your workflow) |

## Usage

### Direct Docker Command

#### Basic usage - Run a single Beets command:

```bash
docker run --rm \
  -v /path/to/config:/config \
  -v /path/to/library:/library \
  ghcr.io/nedra1998/beets:latest \
  list
```

#### Automatic import monitoring:

Monitor a directory and automatically import new music files:

```bash
docker run -d \
  --name beets \
  -v /path/to/config:/config \
  -v /path/to/library:/library \
  -v /path/to/downloads:/import \
  -e IMPORT_DIR=/import \
  -e DEBOUNCE_SECONDS=30 \
  ghcr.io/nedra1998/beets:latest
```

#### Trigger-based import:

Use a trigger file to manually trigger imports:

```bash
docker run -d \
  --name beets \
  -v /path/to/config:/config \
  -v /path/to/library:/library \
  -v /path/to/trigger:/trigger \
  -e TRIGGER_FILE=/trigger/import.trigger \
  -e LIBRARY_DIR=/library \
  ghcr.io/nedra1998/beets:latest
```

Then trigger an import by touching the file:
```bash
touch /path/to/trigger/import.trigger
```

#### Combined monitoring:

Run both import directory and trigger file monitoring simultaneously:

```bash
docker run -d \
  --name beets \
  -v /path/to/config:/config \
  -v /path/to/library:/library \
  -v /path/to/downloads:/import \
  -v /path/to/trigger:/trigger \
  -e IMPORT_DIR=/import \
  -e TRIGGER_FILE=/trigger/import.trigger \
  -e DEBOUNCE_SECONDS=20 \
  ghcr.io/nedra1998/beets:latest
```

### Docker Compose

Here's a complete `docker-compose.yml` example:

```yaml
services:
  beets:
    image: ghcr.io/nedra1998/beets:latest
    container_name: beets
    restart: unless-stopped
    environment:
      # Optional: Set custom paths
      BEETSDIR: /config
      CONFIG_FILE: /config/config.yaml
      
      # Enable automatic import from downloads directory
      IMPORT_DIR: /import
      DEBOUNCE_SECONDS: 30
      
      # Optional: Enable trigger-based import
      # TRIGGER_FILE: /trigger/import.trigger
      # LIBRARY_DIR: /library
    volumes:
      # Beets configuration and database
      - ./config:/config
      
      # Your organized music library
      - /path/to/music:/library
      
      # Directory to monitor for new music
      - /path/to/downloads:/import
      
      # Optional: Trigger file location
      # - ./trigger:/trigger
    
    # Optional: Run a specific command instead of monitoring
    # command: ["list"]
```

#### Minimal Docker Compose Example

For a simple setup with just automatic import monitoring:

```yaml
services:
  beets:
    image: ghcr.io/nedra1998/beets:latest
    container_name: beets
    restart: unless-stopped
    environment:
      IMPORT_DIR: /import
    volumes:
      - ./beets-config:/config
      - /path/to/music:/library
      - /path/to/downloads:/import
```

## Modes of Operation

### 1. Command Mode

If you pass arguments to the container, it will execute that Beets command and exit:

```bash
docker run --rm -v ./config:/config -v ./library:/library \
  ghcr.io/nedra1998/beets:latest list artist:Beatles
```

### 2. Trigger File Monitoring Mode

Enabled when `TRIGGER_FILE` is set. The container monitors the specified file and runs an **in-place import** (using `--nocopy` flag, which means files are scanned and cataloged but not moved from their current location) from `LIBRARY_DIR` when the file is modified. This is useful when:
- You want to manually trigger imports
- An external process manages your files and you don't want Beets to move them
- You want to catalog music without reorganizing your file structure

### 3. Import Directory Monitoring Mode

Enabled when `IMPORT_DIR` is set. The container monitors the directory for new or modified files and automatically imports them after a period of inactivity (`DEBOUNCE_SECONDS`). Files are **moved** to your library. This is useful when:
- You want fully automated imports
- You have a downloads directory that receives new music
- You want files organized and moved to your library

### 4. Combined Mode

Both monitoring modes can run simultaneously if both `TRIGGER_FILE` and `IMPORT_DIR` are set.

## Initial Setup

1. Create a directory for Beets configuration:
   ```bash
   mkdir -p ./beets-config
   ```

2. Create a basic `config.yaml` in that directory:
   ```yaml
   directory: /library
   library: /config/library.db
   
   import:
     move: yes
     copy: no
     write: yes
     log: /config/import.log
   
   plugins: embedart fetchart lyrics
   ```

3. Run the container with appropriate volume mounts

4. On first import, Beets will create the database and organize your music

## Included Plugins

- **chroma**: Acoustic fingerprinting for accurate identification
- **embedart**: Embed album art into music files
- **fetchart**: Fetch album art from various sources
- **lastgenre**: Fetch genres from Last.fm
- **lyrics**: Fetch song lyrics
- **replaygain**: Calculate and apply ReplayGain for consistent volume
- **beetcamp**: Bandcamp integration
- **beets-copyartifacts3**: Copy additional files alongside music

## Advanced Examples

### Import specific directory once:

```bash
docker run --rm \
  -v ./config:/config \
  -v ./library:/library \
  -v ./new-music:/import \
  ghcr.io/nedra1998/beets:latest \
  import /import
```

### Update library metadata:

```bash
docker run --rm \
  -v ./config:/config \
  -v ./library:/library \
  ghcr.io/nedra1998/beets:latest \
  update
```

### List all albums:

```bash
docker run --rm \
  -v ./config:/config \
  -v ./library:/library \
  ghcr.io/nedra1998/beets:latest \
  ls -a
```

## Links

- [Beets Documentation](https://beets.readthedocs.io/)
- [Beets Configuration](https://beets.readthedocs.io/en/stable/reference/config.html)
- [Beets Plugins](https://beets.readthedocs.io/en/stable/plugins/index.html)
- [GitHub Repository](https://github.com/Nedra1998/beets-docker)

## License

This Docker container setup is provided as-is. Beets itself is licensed under the MIT license.
