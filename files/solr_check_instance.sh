#!/bin/bash
# Step through all cores under one instance and throw an exit code if something is not running.
# Exit code 3: possibly not loaded yet, try waiting a bit
# Exit code 4: hard fail, no need to wait any more

set -euo pipefail

if [ "$#" -lt "1" ]; then
	echo "Cowardly refusing to reload all cores on this server. Please specify an instance as the first param."
	exit 2
fi

instance="${1}v4"
target="*/${instance}/*"

status=$(env -i curl "http://localhost:8080/$instance/admin/cores?wt=json" -sS)
for core in $(find /var/lib/solr -maxdepth 2 -mindepth 2 -path "$target" -type d -not -name logs); do
	if [[ ! -f "${core}/core.properties" ]]; then continue; fi

	index=$(basename $core)
	echo "Checking '$instance/$index'"
	failure=$(echo "$status" | jq ".initFailures.$index")
	ping=$(curl "http://localhost:8080/$instance/$index/admin/ping?wt=json" -sS -o /dev/null -w "%{http_code}")
	uptime=$(echo "$status" | jq ".status.$index.uptime")

	if [ "$failure" !=  "null" ]; then
		echo "Failed core $core, index $index has failure $failure"
		exit 4
	fi
	if [ "$ping" -ge "500" ]; then
		echo "Failed pinging $core, index $index returned HTTP $ping"
		exit 4
	fi
	if [ "$uptime" ==  "null" ]; then
		echo "Failed core $core, index $index has uptime $uptime. Try waiting a bit."
		exit 3
	fi
	if [ "$ping" -ne "200" ]; then
		echo "Failed pinging $core, index $index returned HTTP $ping. Try waiting a bit."
		exit 3
	fi
done
