#!/usr/bin/env python3

# Specs: https://gitlab.gnome.org/GNOME/gnome-desktop/-/work_items/191
# Entry code: https://gitlab.gnome.org/GNOME/gnome-control-center/-/blob/main/panels/background/cc-background-xml.c
# Slideshow code: https://gitlab.gnome.org/GNOME/gnome-desktop/-/blob/master/libgnome-desktop/gnome-bg/gnome-bg-slide-show.c

import os
import re
import sys
import xml.etree.ElementTree as ET

from itertools import chain
from argparse import ArgumentParser
from datetime import datetime, timedelta
from pathlib import Path

ASKED_CONFIRM = False
DURATION_DEFAULT = 2
RENDERING_CHOICSE = [
    "none",
    "wallpaper",
    "centered",
    "scaled",
    "stretched",
    "zoom",
    "spanned",
]
RENDERING_DEFAULT = "stretched"
SECONDS_PER_DAY = 24 * 60 * 60
WRITE_DEFAULT = False
XDG_DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))


def main() -> None:
    # Parse parameters
    parser = parser_create()
    args = parser.parse_args()

    try:
        # Get list of files
        files = list(chain.from_iterable(map(filelist_generator, args.files)))
        if not files:
            raise ValueError("No files in provided directories")

        # Normalize slideshow name
        slideshow_name = re.sub(r"[^a-z0-9_.-]", "-", args.name.lower()).strip(".-")
        if not slideshow_name:
            raise ValueError(f"{slideshow_name}: Cannot be turned into filename")

        # Get slideshow path
        if args.path.suffix == ".xml":
            slideshow_dir = args.path.parent
            slideshow_file = args.path.name
        else:
            slideshow_dir = args.path
            slideshow_file = f"{slideshow_name}.xml"

        slideshow_path = slideshow_dir / slideshow_file

        # Get entry path
        entry_dir = XDG_DATA_HOME / "gnome-background-properties"
        entry_file = f"desktop-backgrounds-{slideshow_name}.xml"
        entry_path = (entry_dir / entry_file).resolve()

        # Make slideshow XML file
        slideshow = slideshow_make(files, args.duration)

        # Make entry XML file
        entry = entry_make(args.name, slideshow_path, args.rendering)

        # Write slideshow file
        if args.write and confirm_replace(slideshow_path):
            actual_slideshow_path = slideshow_path
        else:
            actual_slideshow_path = Path(slideshow_path.name)

        if not actual_slideshow_path.parent.exists():
            actual_slideshow_path.parent.mkdir(parents=True)

        with actual_slideshow_path.open("wb") as f:
            f.write(ET.tostring(slideshow, encoding="UTF-8") + b"\n")

        # Write entry file
        if args.write and confirm_replace(entry_path):
            actual_entry_path = entry_path
        else:
            actual_entry_path = Path(entry_path.name)

        if not actual_entry_path.parent.exists():
            actual_entry_path.parent.mkdir(parents=True)

        with actual_entry_path.open("wb") as f:
            f.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
            f.write(b'<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">\n')
            f.write(ET.tostring(entry, encoding="UTF-8") + b"\n")

        # Print output files if deployment is needed
        slideshow_path = home_relative(slideshow_path)
        actual_slideshow_path = home_relative(actual_slideshow_path)
        entry_path = home_relative(entry_path)
        actual_entry_path = home_relative(actual_entry_path)

        if (slideshow_path, entry_path) != (actual_slideshow_path, actual_entry_path):
            if ASKED_CONFIRM:
                print("")

            print("Deploy files:")
            if actual_slideshow_path != slideshow_path:
                print(f"mv {actual_slideshow_path} {slideshow_path}")
            if actual_entry_path != entry_path:
                print(f"mv {actual_entry_path} {entry_path}")
    except Exception as e:
        sys.exit(f"{parser.prog}: {e}")


def confirm_replace(file: Path) -> bool:
    global ASKED_CONFIRM

    if file.exists():
        ASKED_CONFIRM = True
        answer = input(f"{file} already exists, replace it? [y/N]: ").strip()
        return answer.lower() in ("y", "yes")
    else:
        return True


def entry_make(name: str, path: Path, rendering: str) -> ET.Element:
    # Build XML tree
    wallpapers = ET.Element("wallpapers")

    wallpaper = ET.SubElement(wallpapers, "wallpaper", {"deleted": "false"})
    ET.SubElement(wallpaper, "name").text = name
    ET.SubElement(wallpaper, "filename").text = str(path.resolve())
    ET.SubElement(wallpaper, "options").text = rendering

    # Indent tree
    ET.indent(wallpapers)

    return wallpapers


def filelist_generator(file: Path):
    if file.is_file():
        yield file
    elif file.is_dir():
        yield from sorted(f for f in file.iterdir() if f.is_file())
    else:
        raise FileNotFoundError(f"{file}: No such file or directory")


def home_relative(path: Path) -> Path:
    path = path.resolve()
    home = Path.home()

    if path.is_relative_to(home):
        return "~" / path.relative_to(home)
    else:
        return path


def parser_create() -> ArgumentParser:
    parser = ArgumentParser(
        description="Generate GNOME slideshow background XML files.",
    )

    parser.add_argument(
        "-d",
        "--duration",
        help="duration in seconds for image transitions (default: %(default)s)",
        type=int,
        default=DURATION_DEFAULT,
    )
    parser.add_argument(
        "-n",
        "--name",
        help="background display name",
        type=str,
        required=True,
    )
    parser.add_argument(
        "-p",
        "--path",
        help="path to slideshow XML file",
        type=Path,
        required=True,
    )
    parser.add_argument(
        "-r",
        "--rendering",
        help="background rendering (default: %(default)s): %(choices)s",
        type=str,
        default=RENDERING_DEFAULT,
        choices=RENDERING_CHOICSE,
        metavar="RENDERING",
    )
    parser.add_argument(
        "-w",
        "--write",
        help="write files at destination (default: %(default)s)",
        default=WRITE_DEFAULT,
        action="store_true",
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="files of the slideshow, directories are expanded with a depth of 1",
        type=Path,
    )

    return parser


def slideshow_make(files: list[Paths], duration: int) -> ET.Element:
    dt = datetime.fromisoformat("1970-01-01T00:00:00")

    # Build XML tree
    background = ET.Element("background")

    # Set start time
    starttime = ET.SubElement(background, "starttime")
    for field in ["year", "month", "day", "hour", "minute", "second"]:
        ET.SubElement(starttime, field).text = "{:02d}".format(getattr(dt, field))

    if len(files) == 1:
        # Add single slide
        slideshow_make_static(background, files[0], SECONDS_PER_DAY)
    else:
        # Calculate transition time
        static_time = SECONDS_PER_DAY - (duration * len(files))
        if static_time < 0:
            raise ValueError("Too many images, static image time is negative")

        static_duration = static_time // len(files)
        remainder = static_time % len(files)

        # Add static slides and transitions
        for pair in zip(files, files[1:] + files[:1]):
            transition_duration = duration
            if pair[0] == files[-1]:
                transition_duration += remainder

            slideshow_make_static(background, pair[0], static_duration)
            slideshow_make_transition(background, pair, transition_duration)

    # Indent tree
    ET.indent(background)

    return background


def slideshow_make_static(root: ET.Element, file: Path, duration: int):
    time = timedelta(seconds=duration)

    root.append(ET.Comment(f"{file.name} for {time} hours"))
    static = ET.SubElement(root, "static")
    ET.SubElement(static, "duration").text = str(duration)
    ET.SubElement(static, "file").text = str(file.resolve())


def slideshow_make_transition(root: ET.Element, pair: (Path, Path), duration: int):
    time = timedelta(seconds=duration)

    root.append(ET.Comment(f"{pair[0].name} to {pair[1].name} for {time} hours"))
    transition = ET.SubElement(root, "transition")
    ET.SubElement(transition, "duration").text = str(duration)
    ET.SubElement(transition, "from").text = str(pair[0].resolve())
    ET.SubElement(transition, "to").text = str(pair[1].resolve())


def xml_declaration(encoding: str) -> bytes:
    return bytes(f'<?xml version="1.0" encoding="{encoding}"?>', encoding)


if __name__ == "__main__":
    main()
