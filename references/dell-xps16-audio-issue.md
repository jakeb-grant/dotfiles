# Dell XPS 16 2026 (Panther Lake) — Linux Audio Issue

## Status: RESOLVED (2026-04-03)

Audio fully working on kernel 7.0-rc6 after building missing SDCA class modules.

## Hardware

- **Laptop**: Dell XPS 16 2026
- **CPU**: Intel Core Ultra x7 Series 3 (Panther Lake)
- **Audio PCI device**: `00:1f.3 Audio device: Intel Corporation Device e428 (rev 01)`
- **Subsystem ID**: `10280dba` (Dell Device `0dba`)
- **SoundWire codecs**:
  - **Link 0**: CS42L45 jack codec (`mfg_id 0x01fa, part_id 0x4245, version 0x3`)
  - **Link 2**: CS35L57 speaker amps x2 (`mfg_id 0x01fa, part_id 0x3557, version 0x3`)
  - **Link 3**: CS35L57 speaker amps x2 (`mfg_id 0x01fa, part_id 0x3557, version 0x3`)

## Root Cause

Both the prebuilt `linux-mainline` 7.0-rc6 kernel from the miffe repository **and** the AUR `linux-mainline` PKGBUILD are missing `CONFIG_SND_SOC_SDCA_CLASS`:

```
# miffe 7.0-rc6 kernel config:
# CONFIG_SND_SOC_SDCA_CLASS is not set

# AUR linux-mainline PKGBUILD config:
# CONFIG_SND_SOC_SDCA_CLASS — completely absent (not even set to n)
# CONFIG_SND_SOC_SDCA_FDL — also absent (required dependency)

# Arch stock 6.19 kernel config — correct:
CONFIG_SND_SOC_SDCA_CLASS=m
CONFIG_SND_SOC_SDCA_CLASS_FUNCTION=m
CONFIG_SND_SOC_SDCA_FDL=y
```

Without these modules, the CS42L45 SoundWire device had no driver binding — no modalias, no driver in sysfs — causing `sof_sdw` to permanently defer probe.

**This is an AUR packaging issue, not an upstream kernel bug.** The miffe repo likely builds from the same AUR config. Anyone building or installing `linux-mainline` from AUR will hit this on SDCA-based audio hardware (Dell/Lenovo Panther Lake laptops).

Key evidence:
- CS42L45 was `Attached` on SoundWire but `NO DRIVER` bound, no modalias
- All four CS35L57 amps had `cs35l56` driver bound correctly
- SoundWire link 0 (CS42L45) had clock stop timeout: `prepare clock stop failed -110`
- The CS42L45 SDCA class driver (`sdca_class.c`) and firmware (`/lib/firmware/sdca/1fa/1028/dba/`) were both present — just not enabled in the kernel config

### Note on kernel 6.19

The Arch stock 6.19 kernel has `CONFIG_SND_SOC_SDCA_CLASS=m` enabled but hits a **separate bug** — a crash in `sdca_jack_process+0x47/0x3b0` resulting in `-ENOTSUPP` (`-524`). That crash is fixed in 7.0-rc6. Building the missing modules would NOT fix 6.19.

## Fix Applied

Built the two missing SDCA class modules out-of-tree against the running 7.0-rc6 kernel using `~/fix-sdca-modules.sh`:

```bash
# Download source from kernel.org for v7.0-rc6
curl -sL https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/sound/soc/sdca/sdca_class.c?h=v7.0-rc6
curl -sL https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/sound/soc/sdca/sdca_class_function.c?h=v7.0-rc6

# Kbuild:
obj-m += snd-soc-sdca-class.o
snd-soc-sdca-class-y := sdca_class.o
obj-m += snd-soc-sdca-class-function.o
snd-soc-sdca-class-function-y := sdca_class_function.o

# Build and install
make -C /lib/modules/$(uname -r)/build M=/path/to/sdca modules
# compress with zstd, copy to /lib/modules/.../kernel/sound/soc/sdca/
depmod -a
reboot
```

The script (`~/fix-sdca-modules.sh`) automates all of this and checks if modules are already in place before rebuilding.

## Working Result

```
$ cat /proc/asound/cards
 0 [sofsoundwire   ]: sof-soundwire - sof-soundwire
                      DellInc.-XPS16DA16260-0H2HX9

$ wpctl status
Audio
 ├─ Sinks:
 │      83. sof-soundwire HDMI / DisplayPort 3 Output
 │      84. sof-soundwire HDMI / DisplayPort 2 Output
 │      85. sof-soundwire HDMI / DisplayPort 1 Output
 │      86. sof-soundwire Headphones
 │  *   87. sof-soundwire Speaker
 ├─ Sources:
 │  *   88. sof-soundwire Microphones
```

## Behavior on Different Kernels

### Kernel 6.19.10 (Arch stock)

Kernel oops crash in `sdca_jack_process` — **not fixable with module rebuild**:

```
sof_sdw sof_sdw: Failed to register jack: -524
RIP: 0010:sdca_jack_process+0x47/0x3b0 [snd_soc_sdca]
sof_sdw sof_sdw: error -ENOTSUPP: snd_soc_register_card failed -524
```

Also topology ABI mismatch: topology files ABI 3.29.1 vs kernel ABI 3.23.1.

### Kernel 7.0-rc6 (linux-mainline from miffe repo, before fix)

No crash, but permanent deferred probe due to missing `CONFIG_SND_SOC_SDCA_CLASS`:

```
cs35l56 sdw:0:2:01fa:3557:01:2: Cirrus Logic CS35L57 Rev B2 OTP1 fw:4.2.1 (patched=0)
cs35l56 sdw:0:2:01fa:3557:01:2: Slave 2 state check1: UNATTACHED, status was 1
soundwire_intel soundwire_intel.link.0: prepare clock stop failed -110
platform sof_sdw: deferred probe pending: sof_sdw: snd_soc_register_card failed -517
```

### Kernel 7.0-rc6 (after building SDCA class modules)

Fully working. Speakers, headphones, HDMI/DP outputs, and microphone all functional.

## Bug Reports Filed

- **SOF Project**: Filed on https://github.com/thesofproject/linux/issues — initially reported as missing driver/firmware, updated with correct root cause and fix

## Related Issues / References

- [Ubuntu Bug #2139391](https://bugs.launchpad.net/ubuntu/+source/linux-oem-6.17/+bug/2139391) — CS42L45+CS35L57 confirmed working on Dell `10280db3`/`10280db4` with `linux-oem-6.17/6.17.0-1013.13`
- [Phoronix: CS42L45 firmware upstreamed](https://www.phoronix.com/news/Cirrus-CS42L45-Linux-Firmware) — firmware added Jan 2026 for Dell/Lenovo PTL models
- [thesofproject/linux#5515](https://github.com/thesofproject/linux/issues/5515) — related SDCA function detection fix for Dell XPS 14 (Meteor Lake)

## Installed Packages

```
linux 6.19.10.arch1-1       (Arch stock kernel — has sdca_jack_process crash)
linux-mainline 7.0.0-rc6    (from miffe repo — works after building SDCA class modules)
sof-firmware 2025.12.2-1
linux-firmware 20260309-1
pipewire 1:1.6.2-1
pipewire-pulse 1:1.6.2-1
wireplumber 0.5.14-1
alsa-utils (installed)
alsa-ucm-conf (installed)
```

## Setup Notes

### Mainline kernel installed via miffe repo

Added to `/etc/pacman.conf`:

```ini
[miffe]
SigLevel = Optional TrustAll
Server = https://arch.miffe.org/$arch/
```

Then: `pacman -Syy && pacman -S linux-mainline linux-mainline-headers`

GRUB config regeneration required after install: `grub-mkconfig -o /boot/grub/grub.cfg`

### Alternative: Build linux-mainline from AUR with fix baked in

The AUR PKGBUILD has the same missing config. To build with the fix:

```bash
yay -G linux-mainline
cd linux-mainline
echo "CONFIG_SND_SOC_SDCA_CLASS=m" >> config
echo "CONFIG_SND_SOC_SDCA_CLASS_FUNCTION=m" >> config
echo "CONFIG_SND_SOC_SDCA_FDL=y" >> config
makepkg -si
```

Note: Rust support may cause build failures — add `scripts/config --disable RUST` in the `prepare()` function of the PKGBUILD if needed.

### IMPORTANT: Re-run fix after kernel updates

If using the miffe prebuilt kernel: the modules will need to be rebuilt after any kernel update. Run `~/fix-sdca-modules.sh` again. The script checks if modules are already present and skips the build if so.

If building from AUR: re-apply the config additions each time, as `yay -G` pulls a fresh PKGBUILD.
