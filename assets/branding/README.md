# GGLP app icon

A friendly cat head with a leaf-green plus badge on a warm red field:
GGLP's original app mark for its Misskey client.

`app_icon.svg` is the editable source; `app_icon.png` is a generated opaque 1024px master (not committed).
Regenerate all platform assets from the repository root with:

```sh
python3 tool/generate_app_icons.py
```

Requires Python 3.9+, `rsvg-convert` (librsvg), and ImageMagick 7 (`magick`).
No Flutter runtime dependencies are added.

The generator updates the existing iOS/macOS asset catalogs, Android legacy,
adaptive and themed icons, the multi-resolution Windows ICO, and the Linux
window icon bundled by CMake. iOS uses an opaque square for system masking;
desktop and legacy Android assets include rounded corners and transparency.
