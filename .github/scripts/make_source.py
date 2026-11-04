#!/usr/bin/env python3
"""Laver source.json til SideStore/AltStore ud fra den byggede .ipa.

Brug: make_source.py <ipa> <version> <build> <commit> <ud-fil>
"""
import json
import os
import sys
from datetime import datetime, timezone

ipa, version, build, commit, out = sys.argv[1:6]
repo = os.environ.get("GITHUB_REPOSITORY", "Thyxo/Seal-Life")
base = f"https://github.com/{repo}"
raw = f"https://raw.githubusercontent.com/{repo}/main"
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
icon = f"{raw}/App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

source = {
    "name": "Sælliv",
    "identifier": "com.thyxo.seallife.source",
    "subtitle": "En blid vane-tracker med en sæl",
    "description": "Sælliv – vaner, humør og en sæl der svømmer på eventyr. Alt ligger lokalt på telefonen.",
    "iconURL": icon,
    "website": base,
    "tintColor": "#5B8DB8",
    "apps": [
        {
            "name": "Sælliv",
            "bundleIdentifier": "com.thyxo.seallife",
            "developerName": "Thyxo",
            "subtitle": "En blid vane-tracker med en sæl",
            "localizedDescription": (
                "Pas på din sæl ved at klare små vaner. Humør-tjek, butik med tøj, "
                "statistik, widget og Live Activity. Ingen konto, ingen server."
            ),
            "iconURL": icon,
            "tintColor": "#5B8DB8",
            "category": "lifestyle",
            "screenshots": [],
            "versions": [
                {
                    "version": version,
                    "buildVersion": build,
                    "date": now,
                    "localizedDescription": f"Automatisk build af {commit[:7]}.",
                    "downloadURL": f"{base}/releases/download/latest/SealLife.ipa",
                    "size": os.path.getsize(ipa),
                    "minOSVersion": "17.0",
                }
            ],
            "appPermissions": {
                "entitlements": ["com.apple.security.application-groups"],
                "privacy": {},
            },
        }
    ],
    "news": [],
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(source, f, ensure_ascii=False, indent=2)
print(f"source.json: version {version} ({build}), {os.path.getsize(ipa)} bytes")
