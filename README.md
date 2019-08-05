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

 * [Android Developer Tools][4]

[4]: https://developer.android.com/studio/releases/platform-tools

### Extract
```
unzip crosshatch-PQ1A.181205.006-factory-1947dcec.zip
cd crosshatch-PQ1A.181205.006/
```

### Flash

 1. Unlock "Developer Settings" by tapping "About -> Build" several times
 2. Ensure "Enable OEM Unlocking" is enabled under "Developer Settings".
 3. Unlock the bootloader.
   ```
   adb reboot bootloader
   fastboot flashing unlock
   ```

 4. Repeat steps #1 and #2
 5. Flash new factory images
   ```
   ./flash-all.sh
   ```

## Build ##

### Requirements ###

 * Linux host system
 * Docker
 * x86_64 CPU
 * 10GB+ available memory
 * 350GB+ available disk

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

### Clean ###

Do basic cleaning without deleting cached artifacts/sources:
```
make clean
```

Clean everything but keys
```
make mrproper
```

### Test ###

* Build a given device twice from scratch and compare with diffoscope
* Future: Run Android Compatibility Test Suite

```
make test
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
make install
```

### Update ###

Build latest config from upstream sources:

```
make DEVICE=crosshatch config manifest
```

## Notes ##

Use at your own risk. You might be eaten by a grue.
