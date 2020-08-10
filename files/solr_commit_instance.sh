#!/bin/bash
# Step through all cores under one instance and issue a hard-commit.

set -euo pipefail

if [ "$#" -lt "1" ]; then
	echo "Cowardly refusing to reload all cores on this server. Please specify an instance as the first param."
	exit 2
fi

instance="${1}v4"
target="*/${instance}/*"
delay="1"
if [ "$#" -ge "2" ]; then
	delay="$2"
fi

exitcode="0"
for core in $(find /var/lib/solr -maxdepth 2 -mindepth 2 -path "$target" -type d -not -name logs); do
	if [[ ! -f "${core}/core.properties" ]]; then continue; fi

	index=$(basename $core)
	echo "Committing '$instance/$index'"
	status=$(env -i curl "http://localhost:8080/$instance/$index/update?commit=true&wt=json" -w "%{http_code}" -o /dev/null -sS)
	if [ "$status" -ne "200" ]; then
		echo "Failed committing $core, moving on to the next core."
		exitcode="2"
	fi
	echo "Sleeping for ${delay}s"
	sleep $delay
done

exit $exitcode

