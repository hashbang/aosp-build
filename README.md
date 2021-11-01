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

Please join us on IRC: ircs://irc.hashbang.sh/#!mobile

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

  | Device      | Codename   | Tested | Verifiable | Secure Boot | Download |
  |-------------|:----------:|:------:|:----------:|:-----------:|:--------:|
  | Pixel 3a XL | Bonito     | FALSE  | FALSE      | AVB 2.0     | Soon™    |
  | Pixel 3a    | Sargo      | TRUE   | FALSE      | AVB 2.0     | Soon™    |
  | Pixel 3 XL  | Crosshatch | TRUE   | FALSE      | AVB 2.0     | Soon™    |
  | Pixel 3     | Blueline   | FALSE  | FALSE      | AVB 2.0     | Soon™    |

## Install ##

Refer to [GrapheneOS CLI install].

[GrapheneOS CLI install]: https://grapheneos.org/install/cli

### Notes

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

Most of the dependencies are "contained". Only minimal software requirements
exist for the controlling host that cannot be contained easily because of the
bootstrapping problem:

* GNU core utilities
* GNU Make
* Python 3 dependencies: jinja2

They should be packaged by your distribution under the following names (adjust
slight distro differences yourself):

```
coreutils make python3 python3-jinja2
```

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

### Release ###

1. Update references to latest upstream sources.

  ```
  make config
  ```

1. Regenerate the git-repo XML manifest files.

  ```
  make manifest
  ```

1. Build all targets impacted by given change

  ```
  make DEVICE=crosshatch release
  ```

1. Commit changes to a PR

## Review ##

Patchsets that base on AOSP will carry their patchset forward using `git
rebase`. In case you use aosp-build you might be interested in an ongoing
review of this patchset across rebases. For this, checkout `make review`.

Refer to https://github.com/ypid/android-review for one public instance of such
a review.

### How it works? ###

We use the hash locked manifest that [aosp-build] produces from AOSP to
whatever you have checked out.

## Notes ##

Use at your own risk. You might be eaten by a grue.
