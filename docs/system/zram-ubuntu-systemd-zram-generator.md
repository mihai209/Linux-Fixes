# ZRAM on Ubuntu with systemd-zram-generator

This guide configures compressed RAM swap (ZRAM) on Ubuntu using
`systemd-zram-generator`. ZRAM creates a compressed block device in RAM and
exposes it as swap. It does **not** disable or replace Linux's filesystem
cache; the kernel reclaims cache automatically when applications need memory.

## Example environment and observed result

The configuration below was tested interactively on an Ubuntu 26.04.1 system
with approximately 8 GiB RAM.

Before setup:
- RAM: 7.6 GiB
- Existing swap: `/swapfile`, 512 MiB
- ZRAM: not present

After setup:
- `/dev/zram0`: approximately 3.8 GiB
- ZRAM swap priority: 100
- Existing `/swapfile`: retained, priority -1
- Total swap reported by `free -h`: approximately 4.3 GiB

The active algorithm reported by `zramctl` on that machine was `lzo-rle`,
although the configuration requested `zstd`. Therefore, do not assume that
the requested algorithm was applied; verify it on the target machine.

## 1. Install the generator

```bash
sudo apt update
sudo apt install systemd-zram-generator
```

## 2. Configure ZRAM

Create `/etc/systemd/zram-generator.conf`:

```ini
[zram0]
zram-size = 4096
compression-algorithm = zstd
swap-priority = 100
```

For example, write it with:

```bash
sudo mkdir -p /etc/systemd
sudo tee /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = 4096
compression-algorithm = zstd
swap-priority = 100
EOF
```

This requests a 4096 MiB ZRAM device, the `zstd` compression algorithm,
and a swap priority higher than the common default priority of a disk swapfile.
The actual available size may be displayed as about 3.8 GiB.

## 3. Start the device

```bash
sudo systemctl daemon-reload
sudo systemctl start dev-zram0.swap
```

If the generated swap unit name is not available on a particular
systemd/generator version, reboot after installing and configuring the
generator:

```bash
sudo reboot
```

Do not run both activation paths unnecessarily. The device should be managed
by the generator; avoid manually formatting or initializing `/dev/zram0`.

## 4. Verify

```bash
zramctl
swapon --show
free -h
cat /sys/block/zram0/comp_algorithm
```

Check that:
- `/dev/zram0` appears in `zramctl` and `swapon --show`.
- Its swap priority is higher than the disk swapfile's priority.
- The original swapfile remains enabled if you intend to keep it as a fallback.
- The active compression algorithm is shown in square brackets in
  `/sys/block/zram0/comp_algorithm` (for example, `lzo-rle [zstd]` means
  `zstd` is selected).

If `zramctl` reports `lzo-rle` while the config requests `zstd`, inspect
the supported algorithms with the command above and check the generator's
journal/logs. Do not claim that Zstandard is active until the output confirms
it. The observed example machine showed `lzo-rle`; the reason was not
established during that troubleshooting session.

## Notes

- ZRAM is compressed swap in RAM; it is not additional physical RAM.
- A 4 GiB ZRAM device does not reserve 4 GiB of physical RAM immediately.
  Physical memory is used as pages are written to the device, with compression
  affecting the actual amount consumed.
- Keep an existing disk swapfile unless you have a specific reason to remove it.
- Linux `buff/cache` is normal and generally reclaimable. ZRAM does not make
  the cache disappear and should not be configured merely to eliminate the
  cache figure shown by `free`.
- Swap usage can remain nonzero after memory pressure has passed; this alone
  does not mean ZRAM or the system is malfunctioning.

## Roll back

Remove the generator configuration and reboot to remove the generated ZRAM
device cleanly:

```bash
sudo rm /etc/systemd/zram-generator.conf
sudo reboot
```

After reboot, verify with `zramctl` and `swapon --show`. The existing
`/swapfile` is not removed by these steps.
