"""Fetch external Blizzard UI inputs for controller tests; never ship them.

The default revision is reproducible. CI also checks the moving Forever branch
to catch client API drift before producing an install artifact.
"""

import argparse
import hashlib
import pathlib
import urllib.request

REVISION = "bebcb6bf309cf41b41bd74f8ca651e6a105b2676"
SOURCES = {
    "Utility.lua": "Blizzard_GamepadSmartNavigation/Utility.lua",
    "SmartNavigation.lua": "Blizzard_GamepadSmartNavigation/SmartNavigation.lua",
    "FrameControlsManager.lua": "Blizzard_GamepadSharedUtility/FrameControlsManager.lua",
    "Blizzard_SettingsPanel.lua": "Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua",
}


def fetch(destination, latest=False):
    revision = "forever" if latest else REVISION
    destination.mkdir(parents=True, exist_ok=True)
    for name, source in SOURCES.items():
        url = f"https://raw.githubusercontent.com/Gethe/wow-ui-source/{revision}/Interface/AddOns/{source}"
        with urllib.request.urlopen(url, timeout=30) as response:
            data = response.read()
        (destination / name).write_bytes(data)
        print(f"{revision} {name} sha256={hashlib.sha256(data).hexdigest()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=pathlib.Path)
    parser.add_argument("--latest", action="store_true")
    args = parser.parse_args()
    fetch(args.destination, args.latest)
