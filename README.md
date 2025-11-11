[pschmitt.dev](https://pschmitt.dev)

## Updating the favicon

Use the helper script to sync the local favicon assets with Gravatar:

```bash
scripts/update-favicon.sh           # uses the default profile hash
scripts/update-favicon.sh you@example.com
```

The script downloads the requested avatar, writes `favicon.png`, and regenerates `favicon.ico`. It requires `curl` plus ImageMagick 7 (`magick`) in your `PATH`. Override the defaults via CLI flags like `--email`, `--hash`, `--size`, `--icon-sizes`, `--png-path`, or `--ico-path`, or set the `PNG_SIZE`, `ICON_SIZES`, `PNG_PATH`, and `ICO_PATH` environment variables.
