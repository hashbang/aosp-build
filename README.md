# AOSP Build #

<http://github.com/hashbang/aosp-build>

## About ##

A build system for AOSP and AOSP-based ROMs that allows for easy customization,
and automation while optimizing for reproducible builds.

By default this repo will build latest vanilla AOSP as a baseline, which also
serves as the baseline E2E test.

Any third party rom project need only include their own customized version
of the Makefile and config.yml from this repo, along with any desired patches.

## Support ##

Please join us on IRC: ircs://irc.hashbang.sh/#!os

## Features ##

### Current

 * 100% Open Source and auditable
   * Except for mandatory vendor blobs hash verified from Google Servers
 * Automated build system:
   * Completely run inside Docker for portability
   * Customize builds from central config file.
   * Automatically pin hashes from upstreams for reproducibility
   * Automated patching/inclusion of upstream Android Sources

## Devices ##

  | Device     | Codename   | Tested | Verifiable | Secure Boot | Download |
  |------------|:----------:|:------:|:----------:|:-----------:|:--------:|
  | Pixel 3 XL | Crosshatch | TRUE   | FALSE      | AVB 2.0     | Soon™    |
  | Pixel 3    | Blueline   | FALSE  | FALSE      | AVB 2.0     | Soon™    |
  | Pixel 2 XL | Taimen     | TRUE   | FALSE      | AVB 1.0     | Soon™    |
  | Pixel 2    | Walleye    | FALSE  | FALSE      | AVB 1.0     | Soon™    |
  | Pixel XL   | Marlin     | TRUE   | FALSE      | dm-verity   | Soon™    |
  | Pixel      | Sailfish   | TRUE   | FALSE      | dm-verity   | Soon™    |

## Install ##

### Requirements ###

 * OSX/Linux host system
 * [Android Developer Tools][4]

[4]: https://developer.android.com/studio/releases/platform-tools

### Extract
```
unzip crosshatch-PQ1A.181205.006-factory-1947dcec.zip
cd crosshatch-PQ1A.181205.006/
```

### Flash

Unlock the bootloader.

NOTE: You'll have to be in developer mode and enable OEM unlocking

```
adb reboot bootloader
fastboot flashing unlock
```

Once the bootloader is unlocked it will wipe the phone and you'll have to do
basic setup to be able to drop into fastboot. You can skip everything since
you'll be starting from scratch again after flashing #!OS

Reboot phone in fastboot and flash

#### Pixel

```
adb reboot bootloader
./flash-all.sh
```

#### Pixel 2+

```
adb reboot fastboot
./flash-all.sh
```

## Building ##

### Requirements ###

 * Linux host system
 * Docker
 * x86_64 CPU
 * 10GB+ available memory
 * 60GB+ disk

### Generate Signing Keys ###

Each device needs its own set of keys:
```
make DEVICE=crosshatch keys
```

### Build Factory Image ###

Build flashable images for desired device:
```
make DEVICE=crosshatch clean build release
```

## Develop ##

## Configure ##

In addition to the AOSP (default) configuration, configurations exist to
build using default sources from other compatible android projects:

  | Config     | Tested | Verifiable | Sources                        |
  |------------|:------:|:----------:|:------------------------------:|
  | Hashbang   | TRUE   | FALSE      | https://github.com/hashbang/os |
  | CalyxOS    | FALSE  | FALSE      | https://github.com/grapheneos  |
  | GrapheneOS | FALSE  | FALSE      | https://gitlab.com/calyxos     |

### clean ###

Do basic cleaning without deleting cached artifacts/sources:
```
make clean
```

Clean everything but keys
```
make mrproper
```

### Compare ###

Build a given device twice from scratch and compare with diffoscope:
```
make shell
```

### Edit ###

Create a shell inside the docker environment:
```
make shell
```

### Patch ###

Output all untracked changes in android sources to a patchfile:
```
make diff > patches/my-feature.patch
```

### Flash ###
```
adb reboot fastboot
make install
```

## Release ##

WIP

### Update ###

Build latest config from upstream sources:

```
make DEVICE=crosshatch config manifest
```

## Notes ##

Use at your own risk. You might be eaten by a grue.
