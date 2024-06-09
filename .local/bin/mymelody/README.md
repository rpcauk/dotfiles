# MyMelody

- requires ffmpeg
- build venv first
- config stored in $XDG_CONFIG_DIR/mymelody/config.json
- spotify cache stored in $XDG_CACHE_DIR/mymelody/cache.json
- collection of songs stored in $XDG_DATA_DIR/mymelody/data.json
- config requires client id, secret, and places to put downloads
- first time will require spotify auth url thing, then it's fine

## TODO:
- Allow searching through through artists, songs, and albums
- Compare downloads to collection (get diff)
- Compare/merge songs of same name (option/different command)
  - Match name (optional: artist, album)