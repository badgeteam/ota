#!/bin/sh
badge_ids=$(jq -r '.[].id' badges.json)

# find .bin files
binfiles=$(for id in $badge_ids; do [ -f "$id.bin" ] && echo $id; done)
dev_binfiles=$(for id in $badge_ids; do [ -f "${id}_dev.bin" ] && echo $id; done)

# TODO: try to extract version info from .bin files?
# [[ $(head -c 53 mch2022.bin | tail -c 5) =~ [0-9]\.[0-9]\.[0-9] ]] && echo 'version found' || echo 'no version'
# grep --text --only-matching -P '[^\d]\d\.\d\.\d[^\d]' mch2022.bin | head -1

# construct table rows from data
table_rows=$(echo $(cat badges.json) \"$binfiles\" \"$dev_binfiles\" | jq -rs '
	.[1,2] |= split(" ")
	| .[1] as $bins
	| .[2] as $dev_bins
	| .[0][] | . as $badge
| "		<tr>
			<td>\(.name)</td>
			<td>\(if $bins | index($badge.id) != null then "<a href=\"\(.id).bin\">
				\(.version.name)<br/><small>\(.version.date)</small>
			</a>" else "&mdash;" end)</td>
			<td>\(if $dev_bins | index($badge.id) != null then "<a href=\"\(.id)_dev.bin\">
				\(.version_dev.name)<br/><small>\(.version_dev.date)</small>
			</a>" else "&mdash;" end)</td>
			<td><a href=\"bootloader/\(.bootloader.file)\">\(.bootloader.name)</a></td>
			<td>\(if .flash then "<a href=\"partitions/\(.flash.partition_table // "\(.id)_\(.flash.size).bin")\">\(.flash.size)</a>" else "&mdash;" end)</td>
		</tr>"
')

table_rows="<tr>
			<th>Badge</th>
			<th>Firmware<br/><small>release</small></th>
			<th>Firmware<br/><small>development</small></th>
			<th>Bootloader</th>
			<th>Partition&nbsp;table</th>
		</tr>
$table_rows"

# replace table in index.html
perl -0pi.bak -e "s@<table>.*</table>@<table>\n\t\t${table_rows}\n\t</table>@s" index.html
