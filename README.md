# Badge.team OTA Updates
This repository contains the firmware binaries for the badges we support.
It is published as the webroot of https://ota.badge.team

## Maintainers
 - Renze Nicolai: SHA2017, HackerHotel 2019, Disobey 2019, Troopers 2019
 - Heikki Juva: Disobey 2020
 - Tom Clement: CampZone 2019

## Firmware release hook
The [release hook](.github/workflows/release-hook.yml) workflow is an easy way
to push firmware releases to this OTA service. It can be used by calling the
hook from a workflow in the firmware repository.

### Usage
1. Make sure the `firmware_repo` property is set in `badges.json`
1. Publish a release
1. Attach the firmware binary as a release asset (e.g. using `gh release upload`)
1. Call the release hook using [`peter-evans/repository-dispatch@v2`]
    * This requires a suitable Personal Access Token, see [manual][repo-dispatch-action/manual/token])

    Payload (example):
    ```JSON
    {
      "device_id": "mch2022",
      "device_name": "MCH2022",
      "tag": "v2.0.5",
      "channel": "dev",
      "fw_main": "launcher.bin"
    }
    ```
    * `device_id` should correspond to an entry in [`badges.json`](badges.json)
    * `fw_main` should match the firmware binary asset on the release
        * `fw_main` is also used to look for a [matching][matching-elf] `.elf` release asset.
          If found, it is downloaded and added as `{device_id}-{tag}.elf`.
    * `channel` can be `release` or `dev`; other channels do not show up in the
      [index].
    * `tag` is used as the new `.version.name` or `.version_{channel}.name`.

    The release hook then downloads the firmware release asset, `launcher.bin`
    in the example above, replacing the old binary, and a PR is created for you
    to review and publish the OTA update.

[`peter-evans/repository-dispatch@v2`]: https://github.com/peter-evans/repository-dispatch/tree/v2/
[repo-dispatch-action/manual/token]: https://github.com/peter-evans/repository-dispatch/tree/v2/#token
[matching-elf]: https://github.com/badgeteam/ota/blob/d71e22cc77aef103044563d0b4eb60ead8712fd5/.github/workflows/release-hook.yml#L98
[index]: https://ota.badge.team

#### Example: [mch2022-firmware-esp32 > cd-release.yml](https://github.com/badgeteam/mch2022-firmware-esp32/blob/58e85c1e44e29772cdf1a9971ba29ed10c02c01d/.github/workflows/cd-release.yml#L30-L51)

## `badges.json` schema
All properties have `string` values.

### `.<i>.id`
Slug to uniquely identify this badge by. Should match the firmware file(s) with the format `{id}.bin` (and `{id}_dev.bin`).

### `.<i>.name`
Display name of the badge.

### `.<i>.url` &ensp; *optional*
URL to a website or webpage about this badge.

### `.<i>.firmware_repo` &ensp; *optional*
Badge firmware GitHub repository. Used in the firmware release hook.

_Example: `badgeteam/mch2022-firmware-esp32`_

### `.<i>.version`
If not set, an attempt will be made to extract a date stamp and version info from the latest `.bin` file.

#### `.<i>.version.date`
Date of the latest version.

#### `.<i>.version.name`
Name of the latest version, e.g. `v1.4.9` or `r5`.

### `.<i>.version_dev` &ensp; *optional*
Same as `.<i>.version` but for development builds.

### `.<i>.bootloader`

#### `.<i>.bootloader.file`
Filename of the bootloader binary.

#### `.<i>.bootloader.name`
Display name of the bootloader.

### `.<i>.flash` &ensp; *optional*

#### `.<i>.flash.size`
Size of the flash in string format. Is used to find a partition table file if `flash.partition_table` is not set.

#### `.<i>.flash.partition_table` &ensp; *optional*
The filename of the partition table. If not set, the file `{id}_{flash.size}.bin` is used.
