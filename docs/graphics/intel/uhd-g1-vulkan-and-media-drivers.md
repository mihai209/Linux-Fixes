# Intel UHD Graphics G1: Mesa, Vulkan, and media acceleration on Ubuntu

## Hardware scope

This guide targets the Intel UHD Graphics G1 integrated GPU commonly paired with the 10th-generation Intel Core i3-1005G1 (Ice Lake). Confirm the exact GPU and distribution before installing packages:

```bash
lscpu | grep -E 'Model name'
lspci -nnk | grep -A3 -Ei 'VGA|Display'
cat /etc/os-release
uname -r
```

Do not install NVIDIA drivers or a discrete Intel Arc driver stack for this integrated GPU.

## Driver architecture

For this generation, the normal Linux graphics stack is:

- **Kernel driver:** `i915`, supplied by the Linux kernel.
- **OpenGL:** Mesa's Intel Iris driver.
- **Vulkan:** Mesa's Intel ANV driver, provided by `mesa-vulkan-drivers`.
- **Video acceleration:** Intel VA-API media driver, normally `intel-media-va-driver` on Ubuntu-family distributions.
- **Firmware:** distribution-provided `linux-firmware`.

The Vulkan driver is not a separate proprietary download from Intel. On Ubuntu-family systems, Mesa is the standard starting point. Intel recommends using the graphics stack supplied by the distribution for normal Linux graphics support; Intel's graphics PPA is mainly for users who deliberately need newer packages or early access.

## Ubuntu / Ubuntu-based distributions (APT)

First update package metadata:

```bash
sudo apt update
```

Install the standard graphics, Vulkan, and diagnostic packages:

```bash
sudo apt install mesa-vulkan-drivers mesa-utils vulkan-tools \
  libvulkan1 linux-firmware
```

Install VA-API media acceleration support and its diagnostic utility:

```bash
sudo apt install intel-media-va-driver vainfo
```

Some distributions may already have one or more of these packages installed. APT will report that no change is needed.

### Optional: 32-bit Vulkan support for Steam

Only if you use Steam or other 32-bit applications and your system has the i386 architecture enabled:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install mesa-vulkan-drivers:i386 libvulkan1:i386
```

## Verify the installation

Check the kernel driver:

```bash
lspci -nnk | grep -A3 -Ei 'VGA|Display'
```

Look for `Kernel driver in use: i915`.

Check Vulkan:

```bash
vulkaninfo --summary
```

The output should show an Intel GPU/device and a Mesa Intel ANV driver. If `vulkaninfo` reports no Vulkan devices, collect its complete output before changing drivers.

Check OpenGL:

```bash
glxinfo -B
```

Check VA-API:

```bash
vainfo
```

A successful VA-API check should identify an Intel driver and list supported profiles. Codec support depends on the GPU generation, media driver, and codec.

## Avoid these common mistakes

- Do not install `intel-media-va-driver-non-free` automatically just because its name sounds more complete. Start with the distribution's standard `intel-media-va-driver`; change only if a documented codec requirement calls for it.
- Do not add Intel's graphics PPA or manually install packages intended for newer Arc, Battlemage, Lunar Lake, or data-center GPUs for this older integrated GPU.
- Do not install a separate `i915` package from a random download site. The kernel driver is part of the Linux kernel.
- Do not assume that installing Vulkan packages guarantees every game or application will work; application runtime, 32-bit libraries, and hardware feature support also matter.

## Troubleshooting information to collect

If Vulkan or hardware acceleration is not working, collect:

```bash
cat /etc/os-release
uname -r
lspci -nnk | grep -A3 -Ei 'VGA|Display'
dpkg -l | grep -E 'mesa-vulkan-drivers|libvulkan1|intel-media-va-driver|linux-firmware'
vulkaninfo --summary
vainfo
```

Redact personal information before sharing logs.

## References

- [Intel: Linux graphics drivers and distribution-provided support](https://www.intel.com/content/www/us/en/support/articles/000091844/graphics.html)
- [Ubuntu package: mesa-vulkan-drivers](https://packages.ubuntu.com/mesa-vulkan-drivers)
- [Intel media driver documentation](https://github.com/intel/media-driver)
- [Intel graphics installation guidance](https://dgpu-docs.intel.com/driver/client/overview.html)


## Verified report: Ubuntu 26.04.1 LTS, Intel ICL GT1

A real system report from Ubuntu 26.04.1 LTS (codename `resolute`) on an Intel Core i3-1005G1 showed:

- Vulkan device: `Intel(R) UHD Graphics (ICL GT1)`, PCI device ID `8086:8a56`.
- Vulkan driver: Mesa Intel open-source driver (ANV), Mesa `26.0.8-1ubuntu0.3`.
- Vulkan API reported by the device: `1.4.335`.
- OpenGL renderer: `Mesa Intel(R) UHD Graphics (ICL GT1)`, OpenGL `4.6`, `Accelerated: yes`.
- VA-API driver: Intel iHD `26.1.2`, initialized successfully.
- Reported VA-API decode profiles included H.264, HEVC Main/Main10, VP8, and VP9.
- The Vulkan loader also listed `llvmpipe` as a CPU software device alongside the Intel GPU. Its presence alone is not an error; applications should select the Intel device for hardware acceleration.

The following loader warnings appeared:

```text
ICD for selected physical device does not export vkGetPhysicalDeviceDisplayPlanePropertiesKHR
ICD for selected physical device does not export vkGetPhysicalDeviceDisplayPropertiesKHR
```

These warnings concern optional display enumeration entry points. In this report, Vulkan still enumerated the Intel GPU and the device reported Vulkan 1.4.335. The warnings alone do not demonstrate a Vulkan rendering failure.

### Additional kernel-driver verification

The report did not include `lspci -k`, so it does not independently prove which kernel driver is bound. Verify it with:

```bash
lspci -nnk | grep -A3 -Ei 'VGA|Display'
```

Expected kernel driver for this generation is generally `i915`; record the actual `Kernel driver in use` line rather than assuming it.


### Confirmed kernel binding (same system)

A follow-up `lspci -nnk` report confirmed:

```text
00:02.0 VGA compatible controller: Intel Corporation Iris Plus Graphics G1 (Ice Lake) [8086:8a56]
    Kernel driver in use: i915
    Kernel modules: i915
```

This confirms the expected `i915` kernel driver is bound to the integrated GPU. PCI identifies the device as Iris Plus Graphics G1, while Mesa's Vulkan/OpenGL output labels the same PCI device as Intel UHD Graphics (ICL GT1).
