"""Patch managed preferences into OmniWM's writable TOML, with a backup.

Preserve unrelated settings, rules, comments and workspace IDs. Validate before
writing; reactivation should leave identical content and create no extra backup.
"""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tomllib
import uuid


def literal(value):
    # Managed values are scalar; JSON's strings/bools/numbers are also valid TOML.
    return json.dumps(value, ensure_ascii=False)


def patch_values(section, values):
    for key, value in values.items():
        line = f"{key} = {literal(value)}"
        section, count = re.subn(rf"(?m)^{re.escape(key)} = [^\n]*$", lambda _: line, section)
        if count > 1:
            raise ValueError(f"Duplicate key: {key}")
        if count == 0:
            section = section.rstrip() + "\n" + line + "\n\n"
    return section


def apply(original, preferences):
    config = tomllib.loads(original)
    if config.get("schemaVersion") != 4:
        raise ValueError("Unsupported OmniWM schema; settings left untouched")
    updated = original

    def tables(values, prefix=""):
        scalars = {k: v for k, v in values.items() if not isinstance(v, dict)}
        if scalars:
            yield prefix, scalars
        for key, value in values.items():
            if isinstance(value, dict):
                yield from tables(value, f"{prefix}.{key}" if prefix else key)

    for table, values in tables(preferences["settings"]):
        updated, count = re.subn(
            rf"(?ms)^\[{re.escape(table)}\]\n.*?(?=^\[|\Z)",
            lambda m: patch_values(m.group(), values), updated,
        )
        if count != 1:
            raise ValueError(f"Missing or duplicate table: {table}")

    found = set()

    def hotkey(match):
        section = match.group()
        item = tomllib.loads(section)["hotkeys"][0]
        binding = preferences["hotkeys"].get(item["id"])
        if binding is not None:
            found.add(item["id"])
        elif item["binding"].startswith("Option+"):
            binding = item["binding"].replace("Option+", "Hyper+", 1)
        return patch_values(section, {"binding": binding}) if binding else section

    updated = re.sub(r"(?ms)^\[\[hotkeys\]\]\n.*?(?=^\[|\Z)", hotkey, updated)
    if found != preferences["hotkeys"].keys():
        raise ValueError("A managed hotkey action is missing from OmniWM settings")

    layouts = preferences.get("workspaceLayouts", {})
    if not set(layouts) <= {w["name"] for w in config["workspaces"]}:
        raise ValueError("Layout refers to a missing workspace")
    if not set(layouts.values()) <= {"niri", "dwindle"}:
        raise ValueError("Unsupported workspace layout")

    def workspace(match):
        section = match.group()
        item = tomllib.loads(section)["workspaces"][0]
        if item["name"] in layouts:
            section = patch_values(section, {"layoutType": layouts[item["name"]]})
        if item.get("displayName") in {"❤️", "🚀"} and item["name"] in {"6", "7"}:
            section = re.sub(r"(?m)^displayName = [^\n]*\n", "", section)
        return section

    updated = re.sub(r"(?ms)^\[\[workspaces\]\]\n.*?(?=^\[|\Z)", workspace, updated)
    pending = dict(preferences["appWorkspaces"])
    names = {w["name"] for w in config["workspaces"]}
    if not set(pending.values()) <= names:
        raise ValueError("App rule refers to a missing workspace")

    def rule(match):
        section = match.group()
        item = tomllib.loads(section)["appRules"][0]
        bundle = item.get("bundleId")
        # Merge into app-wide rules, preserving their UUID/minimum sizes. Leave
        # specific title/role rules alone so dialogs retain their own behavior.
        matchers = {"appNameSubstring", "titleSubstring", "titleRegex", "axRole", "axSubrole"}
        if bundle in pending and not matchers.intersection(item):
            section = patch_values(section, {"assignToWorkspace": pending.pop(bundle)})
        return section

    updated = re.sub(r"(?ms)^\[\[appRules\]\]\n.*?(?=^\[|\Z)", rule, updated)
    for bundle, target in pending.items():
        values = {"id": str(uuid.uuid5(uuid.NAMESPACE_URL, "omniwm:" + bundle)),
                  "bundleId": bundle, "assignToWorkspace": target}
        updated = updated.rstrip() + "\n\n" + patch_values("[[appRules]]\n", values)

    result = tomllib.loads(updated)
    actions = [h["id"] for h in result["hotkeys"]]
    chords = []
    for item in result["hotkeys"]:
        if item["binding"] != "Unassigned":
            chord = item["binding"].replace("Hyper", result["general"]["hyperKeyModifiers"])
            chords.append(tuple(sorted(chord.split("+"))))
    if len(actions) != len(set(actions)) or len(chords) != len(set(chords)):
        raise ValueError("Duplicate OmniWM actions or shortcut chords; settings left untouched")
    return updated


def main():
    root = os.environ.get("XDG_CONFIG_HOME", "")
    root = Path(root) if root.startswith("/") else Path.home() / ".config"
    path = root / "omniwm/settings.toml"
    if not path.exists():
        sys.exit("Open OmniWM once to create settings.toml, then activate Home Manager again")
    preferences = tomllib.loads(Path(sys.argv[1]).read_text())
    original = path.read_text()
    updated = apply(original, preferences)
    if updated != original:
        digest = hashlib.sha256(original.encode()).hexdigest()[:12]
        backup = path.with_name(path.name + ".before-preferences-" + digest)
        if not backup.exists():
            shutil.copy2(path, backup)
        path.write_text(updated)
        print(f"OmniWM preferences applied; backup: {backup}")


if __name__ == "__main__":
    main()
