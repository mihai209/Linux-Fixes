# Mission Center (Flatpak) missing from the KDE application menu

## Symptoms

Mission Center is installed as a system Flatpak and can be launched with:

```bash
flatpak run io.missioncenter.MissionCenter
```

However, it does not appear when searching the KDE Plasma application launcher.

## Checks

Confirm the application is installed:

```bash
flatpak list --app | grep -i mission
```

Check the exported desktop entry:

```bash
ls -l /var/lib/flatpak/exports/share/applications/io.missioncenter.MissionCenter.desktop
```

A system Flatpak normally exports desktop entries below `/var/lib/flatpak/exports/share/applications/`. A user installation normally exports them below `~/.local/share/flatpak/exports/share/applications/`.

## Refresh KDE's application cache

On KDE Plasma 6:

```bash
kbuildsycoca6 --noincremental
```

Then close and reopen the application launcher and search for **Mission Center**.

## If it is still missing

Inspect the desktop entry and its visibility-related keys:

```bash
grep -E '^(Name|Exec|Icon|Type|Categories|NoDisplay|Hidden)=' \
  /var/lib/flatpak/exports/share/applications/io.missioncenter.MissionCenter.desktop
```

Check whether a user-level desktop file is overriding the system export:

```bash
ls -l ~/.local/share/applications/io.missioncenter.MissionCenter.desktop
```

If that file exists and is stale or invalid, inspect it before changing or removing it. Do not blindly overwrite desktop entries.

## Manual user-level copy (last resort)

If the system export is valid but Plasma still does not list it, create a user-level copy:

```bash
mkdir -p ~/.local/share/applications
cp /var/lib/flatpak/exports/share/applications/io.missioncenter.MissionCenter.desktop \
  ~/.local/share/applications/
kbuildsycoca6 --noincremental
```

This is a workaround, not the first step. If the Flatpak is updated and its exported desktop entry changes, the copied file may become stale.

## Verification

- [ ] `flatpak run io.missioncenter.MissionCenter` launches the application.
- [ ] The exported `.desktop` file exists.
- [ ] KDE's service cache has been rebuilt.
- [ ] Mission Center appears in the application launcher.

## Notes

The command `mission-center` is not guaranteed to exist in `PATH` for a Flatpak application. Use the Flatpak application ID to launch it.

This guide documents the checks and workaround. A successful appearance in the application menu should be confirmed on the affected Plasma installation before marking the issue fully resolved.
