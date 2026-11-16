# Mission Center installed from Snap: permission and display startup errors

## Summary

A Mission Center Snap installation may print permission errors while its desktop launcher reads user-directory configuration files. In one reported setup, the application also failed to open the display when launched from a terminal.

This document records the observed case. It does **not** claim that every Mission Center Snap installation has the same cause.

## Reported environment

- Distribution: Ubuntu-based Linux desktop (exact release not recorded)
- Desktop: KDE Plasma
- Session: Wayland
- Mission Center: Snap revision 18, version 1.2.0
- Snap confinement: enforced

## Observed symptoms

The launcher printed errors similar to:

```text
sed: can't read /home/<user>/.config/user-dirs.dirs: Permission denied
cp: cannot open '/home/<user>/.config/user-dirs.locale' for reading: Permission denied
Gdk-WARNING: Failed to open display
```

The process ran under the confined profile:

```text
snap.mission-center.mission-center (enforce)
```

A test from `snap run --shell mission-center` showed:

```text
XDG_RUNTIME_DIR=/run/user/1000/snap.mission-center
WAYLAND_DISPLAY=wayland-0
WAYLAND SOCKET ERROR: [Errno 13] Permission denied
```

The exact user ID and home path are environment-specific. Do not copy them literally.

## Investigation notes

The following were observed in the reported setup:

- The host session exported `DISPLAY=:0` and `WAYLAND_DISPLAY=wayland-0`.
- The host had a Wayland socket at `/run/user/1000/wayland-0`.
- Snap confinement denied reads of `user-dirs.dirs` and `user-dirs.locale`.
- The confined shell could not connect to the Wayland socket in that test.
- Both `GDK_BACKEND=x11` and `GDK_BACKEND=wayland` still ended with `Failed to open display`.

These observations point to a Snap confinement / desktop-integration problem in that particular setup. They do not prove one universal root cause.

## Later application crash

After the desktop window appeared, the terminal repeatedly reported:

```text
MissionCenter::Gatherer-CRITICAL:
Magpie process exited unexpectedly: signal: 11 (SIGSEGV)
```

GTK theme parser warnings were also visible. The crash may be a separate issue. Its root cause was **not confirmed**. Do not assume it is definitely a Mesa, Zink, or GPU-driver bug without further diagnostics.

## Safer next steps

1. Check current Snap connections:

   ```bash
   snap connections mission-center
   ```

2. Check kernel audit messages for explicit AppArmor denials:

   ```bash
   sudo journalctl -k --since "15 minutes ago" |
     grep -iE 'apparmor.*DENIED|mission-center'
   ```

3. If the Snap package remains unreliable, consider testing the Flatpak build instead of weakening AppArmor or changing broad filesystem permissions.

## Switching this application to Flatpak

To replace only Mission Center's Snap installation:

```bash
sudo snap remove --purge mission-center
```

Install Flatpak and configure Flathub if needed:

```bash
sudo apt update
sudo apt install flatpak

flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
```

Install and launch:

```bash
flatpak install flathub io.missioncenter.MissionCenter
flatpak run io.missioncenter.MissionCenter
```

Check the current Flathub listing and application instructions first. A successful Flatpak launch was **not recorded** in this case, so this is an alternative to test, not a verified fix.

## Important cautions

- Do not use `chmod 777` on `~/.config` or `/run/user`.
- Do not disable AppArmor to make one application work.
- Do not disable `snapd` globally if other applications (such as Firefox or Thunderbird) still depend on Snap.
- Removing Mission Center does not require removing other Snap applications.

## Verification status

- [x] Symptoms recorded from a real report
- [x] Snap confinement denials observed
- [x] Wayland socket connection failure observed inside the Snap shell
- [ ] Root cause of the Magpie SIGSEGV confirmed
- [ ] Flatpak replacement tested successfully
