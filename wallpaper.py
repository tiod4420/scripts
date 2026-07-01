#!/usr/bin/env python3

# Specs: https://gitlab.gnome.org/GNOME/gnome-desktop/-/work_items/191
# Entry code: https://gitlab.gnome.org/GNOME/gnome-control-center/-/blob/main/panels/background/cc-background-xml.c
# Slideshow code: https://gitlab.gnome.org/GNOME/gnome-desktop/-/blob/master/libgnome-desktop/gnome-bg/gnome-bg-slide-show.c

import os
import re
import sys
import xml.etree.ElementTree as ET

from argparse import ArgumentParser
from datetime import datetime, timedelta
from pathlib import Path


DEFAULT_DEPLOY = False
DEFAULT_RENDERING = "stretched"
DEFAULT_TRANSITION = 2
CHOICES_RENDERING = [
    "none",
    "wallpaper",
    "centered",
    "scaled",
    "stretched",
    "zoom",
    "spanned",
]
RE_FILENAME = re.compile(r"[^a-z0-9_.-]")
SECONDS_PER_DAY = 24 * 60 * 60
XDG_DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))


def main() -> None:
    # Flag if overwrite confirmation was asked
    asked = False

    # Parse parameters
    parser = parser_create()
    args = parser.parse_args()

    try:
        # Get list of files
        if not (files := [f for file in args.files for f in filelist_generator(file)]):
            raise ValueError("No files in provided directories")

        # Normalize slideshow name
        if not (slideshow_name := RE_FILENAME.sub("-", args.name.lower()).strip(".-")):
            raise ValueError(f"{args.name}: Cannot be turned into filename")

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

        # Make slideshow and entry XML files
        slideshow = slideshow_make(files, args.transition)
        entry = entry_make(args.name, slideshow_path, args.rendering)

        # Write slideshow file
        orig_slideshow_path = slideshow_path
        slideshow_path, slideshow_asked = prepare_path(slideshow_path, args.deploy)
        asked |= slideshow_asked

        with slideshow_path.open("wb") as f:
            f.write(ET.tostring(slideshow, encoding="UTF-8") + b"\n")

        # Write entry file
        orig_entry_path = entry_path
        entry_path, entry_asked = prepare_path(entry_path, args.deploy)
        asked |= entry_asked

        with entry_path.open("wb") as f:
            f.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
            f.write(b'<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">\n')
            f.write(ET.tostring(entry, encoding="UTF-8") + b"\n")

        # Print output files if deployment is needed
        if (slideshow_path, entry_path) != (orig_slideshow_path, orig_entry_path):
            print(f"{'\n' if asked else ''}Deploy files:")

            if slideshow_path != orig_slideshow_path:
                print(f"mv {homepath(orig_slideshow_path)} {homepath(slideshow_path)}")

            if entry_path != orig_entry_path:
                print(f"mv {homepath(orig_entry_path)} {homepath(entry_path)}")
    except (ValueError, FileNotFoundError) as e:
        sys.exit(f"{parser.prog}: {e}")


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


def filelist_generator(file: Path) -> Iterator[Path]:
    if file.is_file():
        yield file
    elif file.is_dir():
        yield from sorted(f for f in file.iterdir() if f.is_file())
    else:
        raise FileNotFoundError(f"{file}: No such file or directory")


def homepath(path: Path) -> Path:
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
        "--deploy",
        help="deploy files at destination (default: %(default)s)",
        default=DEFAULT_DEPLOY,
        action="store_true",
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
        default=DEFAULT_RENDERING,
        choices=CHOICES_RENDERING,
        metavar="RENDERING",
    )
    parser.add_argument(
        "-t",
        "--transition",
        help="duration in seconds for image transitions (default: %(default)s)",
        type=int,
        default=DEFAULT_TRANSITION,
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="files of the slideshow, directories are expanded with a depth of 1",
        type=Path,
    )

    return parser


def prepare_path(file: Path, deploy: bool) -> (Path, bool):
    asked = False

    if not deploy:
        file = Path(file.name)
    elif file.exists():
        asked = True
        answer = input(f"{homepath(file)} exists, overwrite it? [y/N]: ").strip()
        if answer.lower() not in ("y", "yes"):
            file = Path(file.name)

    file.parent.mkdir(parents=True, exist_ok=True)

    return (file, asked)


def slideshow_make(files: list[Paths], duration: int) -> ET.Element:
    dt = datetime.fromisoformat("1970-01-01T00:00:00")

    # Build XML tree
    background = ET.Element("background")

    # Set start time
    starttime = ET.SubElement(background, "starttime")
    for field in ["year", "month", "day", "hour", "minute", "second"]:
        ET.SubElement(starttime, field).text = f"{getattr(dt, field):02d}"

    if len(files) == 1:
        # Add single slide
        slideshow_static(background, files[0], SECONDS_PER_DAY)
    else:
        # Calculate transition time
        if (static_time := SECONDS_PER_DAY - (duration * len(files))) < 0:
            raise ValueError("Too many images, static image time is negative")

        static_duration = static_time // len(files)
        remainder = static_time % len(files)

        # Add static slides and transitions
        for pair in zip(files, files[1:] + files[:1], strict=True):
            transition_duration = duration
            if pair[0] == files[-1]:
                transition_duration += remainder

            slideshow_static(background, pair[0], static_duration)
            slideshow_transition(background, pair, transition_duration)

    # Indent tree
    ET.indent(background)

    return background


def slideshow_static(root: ET.Element, file: Path, duration: int) -> None:
    time = timedelta(seconds=duration)

    root.append(ET.Comment(f"{file.name} for {time} hours"))
    static = ET.SubElement(root, "static")
    ET.SubElement(static, "duration").text = str(duration)
    ET.SubElement(static, "file").text = str(file.resolve())


def slideshow_transition(root: ET.Element, pair: (Path, Path), duration: int) -> None:
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
