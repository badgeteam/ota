#!/bin/bash
badge_ids=$(jq -r '.[].id' badges.json)

# Firmware compiled with ESP-IDF >v4.4, using SemVer-like versioning
check_new=('mch2022')

# ESP32-platform-firmware (ESP-IDF v3.2, no SemVer)
check_old=('sha2017' 'hackerhotel2019' 'campzone2019' 'troopers2019' 'disobey2020' 'pixel')

# is set when a check fails
check_fails=;

check_version_new() {
	badge=$1
	channel=$2	# unset for release, or 'dev' for dev
	error_no_version=;
	error_no_bin=;
	error_no_bin_version=;

	# get version from badges.json
	version_path=".version${channel:+_$channel}.name";
	version=$(jq -r "map(select(.id == \"$badge\"))[0] | $version_path | ltrimstr(\"v\")" badges.json);	# e.g. 2.0.5
	echo "$badge: badges.json [${channel:-release}]: $version";

	if [[ $version == 'null' ]]; then
		error_no_version=true;
		echo "$badge: ⚠️ no ${channel:-release} version in badges.json";
	fi

	# extract version from .bin
	binfile="$badge${channel:+_$channel}.bin"
	if [ ! -f "$binfile" ]; then
		error_no_bin=true;

		if [ ! $error_no_version ]; then	# missing binary for entry in badges.json
			check_fails+=❌;
			echo "$badge: ❌ no $binfile for entry $badge in badges.json" 1>&2;
			return;
		else
			echo "$badge: ⚠️ no $binfile";
		fi
	else
		# bin_version=$(head -c 53 $binfile | tail -c 5);
		# [[ $bin_version =~ [0-9]\.[0-9]\.[0-9] ]] && echo $bin_version || echo null;
		bin_version=$(grep --text --only-matching -P '(?<!\d)\d\.\d\.\d(?!\d)' "$binfile" 2>/dev/null | head -1 || echo null);
		echo "$badge: $binfile: $bin_version";

		if [[ $bin_version == 'null' ]]; then
			error_no_bin_version=true;
			echo "$badge: ⚠️ no version found in firmware binary";
		fi
	fi

	[[ $error_no_version || $error_no_bin || $error_no_bin_version ]] && return;

	if [[ $bin_version == "$version" ]]; then
		echo "$badge: ✅ ${channel:-release} versions match";
	else
		check_fails+=❌;
		echo "$badge: ❌ ${channel:-release} versions don't match" 1>&2;
	fi
}

check_version_old() {
	badge=$1

	# get version from version/{badge}.txt
	version_json=$([ -f "version/$badge.txt" ] && jq -rc '.' "version/$badge.txt");

	if [ -z "$version_json" ]; then
		check_fails+=❌;
		echo "$badge: ❌ no version file" 1>&2;
		return;
	fi
	echo "$badge: version.txt: $version_json";
	version_name=$(jq -r '.name' <<< "$version_json");

	# search for version name in .bin
	if [ ! -f "$badge.bin" ]; then
		check_fails+=❌;
		echo "$badge: ❌ no $badge.bin" 1>&2;
		return;
	else
		bin_version=$(grep --text --only-matching -Pa "\x00$version_name\x00" "$badge.bin" 2>/dev/null | tr -d '\0');

		if [ -z "$bin_version" ]; then
			check_fails+=❌;
			echo "$badge: ❌ version.txt does not match firmware binary" 1>&2;
		else
			echo "$badge: ✅ firmware binary matches";
		fi
	fi
}

for badge in $badge_ids; do
	if grep -oq "$badge" <<< "${check_new[@]}"; then
		check_version_new "$badge";
		[ -f "${badge}_dev.bin" ] && echo && check_version_new "$badge" 'dev';
	elif grep -oq "$badge" <<< "${check_old[@]}"; then
		check_version_old "$badge";
	else
		echo "⚠️ no check for $badge";
	fi
	echo;
done

for check in "${check_new[@]}" "${check_old[@]}"; do
	if ! grep -oq "$check" <<< "$badge_ids"; then
		echo "⚠️ check for $check has no matching entry in badges.json";
	fi
done
echo;

if [ -z "$check_fails" ]; then
	echo "✅ all checks passed ✅";
else
	echo "${#check_fails} checks failed $check_fails" 1>&2;
fi
exit ${#check_fails};
