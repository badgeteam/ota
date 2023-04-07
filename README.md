# Badge.team OTA Updates
This repository contains the firmware binaries for the badges we support.
It is published as the webroot of https://ota.badge.team

## Maintainers
 - Renze Nicolai: SHA2017, HackerHotel 2019, Disobey 2019, Troopers 2019
 - Heikki Juva: Disobey 2020
 - Tom Clement: CampZone 2019


## `badges.json` schema
All properties have `string` values.

### `.<i>.id`
Slug to uniquely identify this badge by. Should match the firmware file(s) with the format `{id}.bin` (and `{id}_dev.bin`).

### `.<i>.name`
Display name of the badge.

### `.<i>.url` &ensp; *optional*
URL to a website or webpage about this badge.

### `.<i>.version`
If not set, an attempt will be made to extract a date stamp and version info from the latest `.bin` file.

#### `.<i>.version.date`
Date of the latest version.

#### `.<i>.version.name`
Name of the latest version, e.g. `v1.4.9` or `r5`.

### `.<i>.version_dev` &ensp; *optional*
Same as `.<i>.version` but for development/nightly builds.

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
