# Teams for Linux: Snap authentication issue and Flatpak camera/microphone permissions

## Environment

This guide records a user-confirmed workaround on Ubuntu with KDE Plasma:

- Teams for Linux 2.32.0 was initially installed as a Snap.
- Microsoft sign-in opened a system authentication prompt in Romanian: “Față, amprentă, PIN sau cheie de securitate” (face, fingerprint, PIN, or security key).
- The prompt did not provide a usable Cancel action, preventing the user from choosing Microsoft Authenticator.
- Switching to the Flathub Flatpak allowed the user to continue using Teams.
- The Flatpak permissions were then expanded to include audio and hardware-device access.

The exact underlying cause of the Snap sign-in failure was not independently established. Treat the Snap-to-Flatpak change as a tested workaround for this environment, not as a universal fix for every Microsoft sign-in problem.

## 1. Install the Flatpak version

Make sure Flathub is configured, then install:

```bash
flatpak install flathub com.github.IsmaelMartinez.teams_for_linux
```

Launch it with:

```bash
flatpak run com.github.IsmaelMartinez.teams_for_linux
```

Complete the Microsoft sign-in flow and confirm that the account can connect before removing the Snap package.

## 2. Optional: enable the app's experimental WebAuthn dialog

If the sign-in flow still gets stuck on a passkey/security-key prompt, the application documents an experimental WebAuthn option. This can expose the application's FIDO2/WebAuthn handling; it does **not** turn Microsoft Authenticator into a passkey and does not guarantee that Authenticator will be offered.

For the Flatpak installation, the per-user configuration directory is:

```text
~/.var/app/com.github.IsmaelMartinez.teams_for_linux/config/teams-for-linux/
```

The following command safely preserves other keys in an existing JSON configuration and enables the documented option:

```bash
python3 - <<'PY'
import json
from pathlib import Path

config_path = (
    Path.home()
    / ".var/app/com.github.IsmaelMartinez.teams_for_linux/config/teams-for-linux/config.json"
)
config_path.parent.mkdir(parents=True, exist_ok=True)

config = {}
if config_path.exists():
    config = json.loads(config_path.read_text(encoding="utf-8"))

config.setdefault("auth", {}).setdefault("webauthn", {})["enabled"] = True
config_path.write_text(
    json.dumps(config, indent=2) + "\n",
    encoding="utf-8",
)
print(f"Updated {config_path}")
PY
```

Restart Teams after changing the configuration:

```bash
flatpak kill com.github.IsmaelMartinez.teams_for_linux
flatpak run com.github.IsmaelMartinez.teams_for_linux
```

If this does not help, disable the option by setting `"enabled": false` in the same JSON file or remove only the `auth.webauthn` entry. Do not delete the entire application profile as a first troubleshooting step.

## 3. Grant microphone/audio and camera/device access

The tested per-user Flatpak override was:

```bash
flatpak override --user \
  --socket=pulseaudio \
  --device=all \
  com.github.IsmaelMartinez.teams_for_linux
```

This adds:

- `pulseaudio` socket access for audio input/output.
- `devices=all` access to host devices, which can allow camera access.

**Security note:** `--device=all` is broad. It grants access to all devices exposed through the Flatpak device context, not only the webcam. Use it only if the narrower permissions provided by the app do not expose the camera correctly and you accept the wider access.

Inspect the effective permissions:

```bash
flatpak info --show-permissions com.github.IsmaelMartinez.teams_for_linux
```

The user-confirmed output included:

```ini
[Context]
sockets=wayland;pulseaudio;fallback-x11;
devices=all;
filesystems=home;xdg-run/pipewire-0;
```

The app already had Wayland, X11 fallback, and PipeWire socket access in that installation. Flatpak permissions only grant sandbox access; they do not prove that the selected microphone or camera works. Verify both in Teams settings and in a test call.

## 4. Remove the old Snap (after confirming Flatpak works)

Only after successful sign-in and a basic Flatpak launch test:

```bash
sudo snap remove teams-for-linux
```

Snap may save a data snapshot when removing the package. This does not remove the separate Flatpak profile.

## 5. Useful verification commands

```bash
flatpak list --app | grep -i teams
flatpak info --show-permissions com.github.IsmaelMartinez.teams_for_linux
flatpak run com.github.IsmaelMartinez.teams_for_linux
```

## Verification status

- **Confirmed in the reported environment:** Flatpak installation launched and Teams sign-in worked after switching from Snap.
- **Confirmed:** the user removed the Snap package successfully.
- **Confirmed:** the Flatpak override was applied and `flatpak info --show-permissions` showed `pulseaudio` and `devices=all`.
- **Not yet confirmed:** an actual Teams call successfully captured microphone audio and camera video.
- **Not established:** a definitive root cause for the Snap authentication prompt.

## References

- [Teams for Linux troubleshooting documentation](https://ismaelmartinez.github.io/teams-for-linux/troubleshooting/)
- [Teams for Linux project](https://github.com/IsmaelMartinez/teams-for-linux)
- [Flatpak command reference](https://docs.flatpak.org/en/latest/flatpak-command-reference.html)
