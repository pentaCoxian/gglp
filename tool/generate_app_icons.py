#!/usr/bin/env python3
"""Regenerate launcher assets. Requires rsvg-convert and ImageMagick 7."""
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/branding/app_icon.svg'


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def resize(source, destination, size, opaque=False):
    destination.parent.mkdir(parents=True, exist_ok=True)
    run('magick', source, '-resize', f'{size}x{size}',
        *(['-alpha', 'off'] if opaque else []), destination)


def main():
    with tempfile.TemporaryDirectory() as temporary:
        tmp = Path(temporary)
        full = tmp / 'full.png'
        desktop = tmp / 'desktop.png'
        run('rsvg-convert', '-w', '2048', '-h', '2048', SOURCE, '-o', full)
        resize(full, ROOT / 'assets/branding/app_icon.png', 1024, opaque=True)
        # Desktop platforms need their own rounded silhouette and transparent margin.
        run('magick', full, '(', '+clone', '-alpha', 'transparent',
            '-fill', 'white', '-draw', 'roundrectangle 96,96 1952,1952 416,416',
            ')', '-alpha', 'off', '-compose', 'CopyOpacity', '-composite', desktop)
        for platform in ('ios', 'macos'):
            catalog = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
            entries = json.loads((catalog / 'Contents.json').read_text())['images']
            for entry in entries:
                size = round(float(entry['size'].split('x')[0]) *
                             float(entry['scale'].removesuffix('x')))
                resize(full if platform == 'ios' else desktop,
                       catalog / entry['filename'], size, opaque=platform == 'ios')
        res = ROOT / 'android/app/src/main/res'
        # Keep the mark inside Android's adaptive-icon safe area.
        paths = ET.parse(SOURCE).getroot().findall('{http://www.w3.org/2000/svg}path')
        mark = [path for path in paths if 'opacity' not in path.attrib]
        vector = ('<vector xmlns:android="http://schemas.android.com/apk/res/android" '
                  'android:width="108dp" android:height="108dp" '
                  'android:viewportWidth="1024" android:viewportHeight="1024">\n'
                  '  <group android:scaleX="0.58" android:scaleY="0.58" '
                  'android:translateX="215.04" android:translateY="215.04">\n')
        monochrome = vector
        for path in mark:
            attributes = {
                'fillColor': path.get('fill', '#000000').replace('none', '#00000000'),
                'pathData': path.attrib['d'],
            }
            for svg_name, android_name in [('stroke', 'strokeColor'),
                                           ('stroke-width', 'strokeWidth'),
                                           ('stroke-linecap', 'strokeLineCap')]:
                if svg_name in path.attrib:
                    attributes[android_name] = path.attrib[svg_name]
            vector += '    <path ' + ' '.join(
                f'android:{key}="{value}"' for key, value in attributes.items()) + '/>\n'
            if path.get('id') in ('cat', 'badge'):
                monochrome += (f'    <path android:fillColor="#FFFFFF" '
                               f'android:pathData="{path.attrib["d"]}"/>\n')
        vector += '  </group>\n</vector>\n'
        monochrome += '  </group>\n</vector>\n'
        (res / 'drawable').mkdir(exist_ok=True)
        (res / 'drawable/ic_launcher_foreground.xml').write_text(vector)
        (res / 'drawable/ic_launcher_monochrome.xml').write_text(monochrome)
        adaptive = ('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                    '  <background android:drawable="@color/ic_launcher_background"/>\n'
                    '  <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
                    '</adaptive-icon>\n')
        for version in ('v26', 'v33'):
            folder = res / f'mipmap-anydpi-{version}'
            folder.mkdir(exist_ok=True)
            content = adaptive
            if version == 'v33':
                content = content.replace('</adaptive-icon>',
                    '  <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
                    '</adaptive-icon>')
            (folder / 'ic_launcher.xml').write_text(content)
        (res / 'values/ic_launcher_colors.xml').write_text(
            '<resources>\n  <color name="ic_launcher_background">#DF4438</color>\n</resources>\n')
        for density, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96,
                              'xxhdpi': 144, 'xxxhdpi': 192}.items():
            resize(desktop, res / f'mipmap-{density}/ic_launcher.png', size)
        run('magick', desktop, '-resize', '256x256', '-define',
            'icon:auto-resize=256,128,64,48,32,16',
            ROOT / 'windows/runner/resources/app_icon.ico')
        resize(desktop, ROOT / 'linux/runner/resources/app_icon.png', 256)


if __name__ == '__main__':
    main()
