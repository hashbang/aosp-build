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

  | Device      | Codename   | Tested | Verifiable | Secure Boot |
  |-------------|:----------:|:------:|:----------:|:-----------:|
  | Pixel 4  XL | Coral      | TRUE   | FALSE      | AVB 2.0     |
  | Pixel 4     | Flame      | FALSE  | FALSE      | AVB 2.0     |
  | Pixel 3a XL | Bonito     | FALSE  | FALSE      | AVB 2.0     |
  | Pixel 3a    | Sargo      | TRUE   | FALSE      | AVB 2.0     |
  | Pixel 3 XL  | Crosshatch | TRUE   | FALSE      | AVB 2.0     |
  | Pixel 3     | Blueline   | FALSE  | FALSE      | AVB 2.0     |
  | Pixel 2 XL  | Taimen     | TRUE   | FALSE      | AVB 1.0     |
  | Pixel 2     | Walleye    | FALSE  | FALSE      | AVB 1.0     |

## Install ##

### Requirements ###

 * [Android Developer Tools][4]

[4]: https://developer.android.com/studio/releases/platform-tools

### Connect

 1. Go to "Settings > About Phone"
 2. Tap "Build number" 7 times.
 3. Go to "Settings > System > Advanced > Developer options"
 4. Enable "USB Debugging"
 5. Connect to device to laptop via short USB C cable
 6. Hit "OK" on "Allow USB Debugging?" prompt on device if present.
 7. Verify ADB connectivity
   ```
   adb devices
   ```
   Note: Should return something like: "7CKY1QD3F       device"

### Flash

 1. Extract

   ```
   unzip crosshatch-PQ1A.181205.006-factory-1947dcec.zip
   cd crosshatch-PQ1A.181205.006
   ```

 2. [Connect](#Connect)
 3. Go to "Settings > System > Advanced > Developer options"
 4. Enable "OEM Unlocking"
 5. Unlock the bootloader via ADB

   ```
   adb reboot bootloader
   fastboot flashing unlock
   ```
   Note: You must manually accept prompt on device.

 6. Flash new factory images

   ```
   ./flash-all.sh
  ```

### Harden

 1. [Connect](#Connect)
 2. Lock the bootloader
   ```
   adb reboot bootloader
   fastboot flashing lock
   ```
 3. Go to "Settings > About Phone"
 4. Tap "Build number" 7 times.
 5. Go to "Settings > System > Advanced > Developer options"
 6. Disable "OEM unlocking"
 7. Reboot
 8. Verify boot message: "Your device is loading a different operating system"
 9. Go to "Settings > System > Advanced > Developer options"
 10. Verify "OEM unlocking" is still disabled

#### Notes

  * Failure to run these hardening steps means -anyone- can flash your device.
  * Past this point if signing keys are lost, all devices are bricked. Backup!

### Update ###

 1. Go to "Settings > System > Developer options" and enable "USB Debugging"
 2. Reboot to recovery
   ```
   adb reboot recovery
   ```
 3. Select "Apply Update from ADB"
 4. Apply Update
   ```
   adb sideload crosshatch-ota_update-08050423.zip
   ```
 5. Go to "Settings > System > Developer options" and disable "USB Debugging"

## Build ##

### Backends ###

#### Local

##### Requirements
 * Docker 10+
 * x86_64 CPU
 * 10GB+ available memory
 * 350GB+ available disk

##### Usage

```
make DEVICE=crosshatch
```

#### VirtualBox

##### Requirements
 * Virtualbox 5+
 * x86_64 CPU
 * 12GB+ available memory
 * 350GB+ available disk

##### Usage

```
make DEVICE=crosshatch BACKEND=virtualbox
```

#### DigitalOcean

##### Requirements
 * Digitalocean API token

##### Usage

```
cp config/env/digitalocean.{sample.,}env
vim config/env/digitalocean.env
make DEVICE=crosshatch BACKEND=digitalocean
```

### Make Targets

#### Default

On a fresh clone you will want to run the default target which will setup
the backend, build the docker image, fetch sources, build the toolchain,
generate signing keys, compile everything, then package a release zip.

The default backend is 'local'.

```
make DEVICE=crosshatch
```

#### Download sources

```
make DEVICE=crosshatch fetch
```

#### Build basic tools

Build tools required for generating signing keys and flashing.
```
make DEVICE=crosshatch tools
```

#### Generate Signing Keys

Each device needs its own set of keys:
```
make DEVICE=crosshatch keys
```

#### Build Release

Build flashable images for desired device:
```
make DEVICE=crosshatch build release
```

#### Clean

Do basic cleaning without deleting cached artifacts/sources:
```
make clean
```

Clean everything but keys
```
make mrproper
```

#### Test

* Build a given device twice from scratch and compare with diffoscope
* Future: Run Android Compatibility Test Suite

```
make test
```

#### Edit ####

Create a shell inside the docker environment:
```
make shell
```

#### Diff ####

Output all untracked changes in android sources to a patchfile:
```
make diff > patches/my-feature.patch
```

#### Flash ####
```
make install
```

#### Update ####

Build latest config from upstream sources:

```
make DEVICE=crosshatch manifest
```

## Notes ##

Use at your own risk. You might be eaten by a grue.
