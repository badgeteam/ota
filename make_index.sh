#!/bin/sh
badge_ids=$(jq -r '.[].id' badges.json)

# find .bin files
binfiles=$(for id in $badge_ids; do [ -f "$id.bin" ] && echo $id; done)
dev_binfiles=$(for id in $badge_ids; do [ -f "${id}_dev.bin" ] && echo $id; done)
debug_files=$(
	echo $(for id in $badge_ids; do
		for debug_file in $(ls $id-*.elf 2> /dev/null); do
			echo $debug_file;
		done;
	done) | jq -csR '.
	| split(" ")
	| map(rtrimstr("\n"))
	| map(
		. as $filename | rtrimstr(".elf")
		| split("-")
		| { badge_id: .[0], fw_version: .[1] }
	)
	| . as $debug_files
	| (map(.badge_id) | unique) as $badge_ids
	| $badge_ids | map(. as $id | {
		($id): $debug_files | map(select(.badge_id == $id) | .fw_version)
	}) | add'
)

# TODO: try to extract version info from .bin files?
# [[ $(head -c 53 mch2022.bin | tail -c 5) =~ [0-9]\.[0-9]\.[0-9] ]] && echo 'version found' || echo 'no version'
# grep --text --only-matching -P '[^\d]\d\.\d\.\d[^\d]' mch2022.bin | head -1


table_header="
		<tr>
			<th rowspan=2>Badge</th>
			<th colspan=2>Firmware</th>
			<th rowspan=2>Debug symbols</th>
			<th rowspan=2>Bootloader</th>
			<th rowspan=2>Partition table</th>
		</tr>
		<tr class="subheadings">
			<th>release</th>
			<th>development</th>
		</tr>
"

# construct table rows from data
table_rows=$(echo $(cat badges.json) \"$binfiles\" \"$dev_binfiles\" $debug_files | jq -rs '
	.[1,2] |= split(" ")
	| .[1] as $bins
	| .[2] as $dev_bins
	| .[3] as $elfs
	| .[0][] | . as $badge
| "		<tr>
			<td>\(if .url then "<a href=\"\(.url)\" target=_blank>\(.name)</a>" else .name end)</td>

			<td>\(if $bins | index($badge.id) != null then "<a href=\"\(.id).bin\">
				\(.version.name)<br/><small>\(.version.date)</small>
			</a>" else "&mdash;" end)</td>

			<td>\(if $dev_bins | index($badge.id) != null then "<a href=\"\(.id)_dev.bin\">
				\(.version_dev.name)<br/><small>\(.version_dev.date)</small>
			</a>" else "&mdash;" end)</td>

			<td>\(if $elfs | has($badge.id) then "<details>
			<summary>\($elfs[.id] | length) files</summary>
			<small>\($elfs[.id] | sort | reverse
				| map("<a href=\"\($badge.id)-\(.).elf\">\($badge.id)-\(.).elf</a>")
				| join("<br/>")
			)</small>
			</details>" else "&mdash;" end)</td>

			<td><a href=\"bootloader/\(.bootloader.file)\">\(.bootloader.name)</a></td>

			<td>\(if .flash then "<a href=\"partitions/\(.flash.partition_table // "\(.id)_\(.flash.size).bin")\">\(.flash.size)</a>" else "&mdash;" end)</td>
		</tr>" | gsub("\n\n"; "\n")
')

# replace table in index.html
perl -p0 -e "s@<table>.*</table>@<table>${table_header}${table_rows}\n\t</table>@s" index.template.html > index.html
