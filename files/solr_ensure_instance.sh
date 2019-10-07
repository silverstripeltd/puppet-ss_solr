#!/bin/bash
# Ensure instance has all cores runnning fine.

set -euo pipefail

if [ "$#" -lt "1" ]; then
	echo "Cowardly refusing to reload all cores on this server. Please specify an instance as the first param."
	exit 2
fi

instance="${1}"

check_result="0"
/usr/local/bin/solr_check_instance.sh "$instance" || check_result="$?"

wait_time="0"
hard_fails="0"
until [ "$check_result" -eq "0" ]; do

	wait_time=$(( wait_time + 30 ))
	if [ "$wait_time" -gt "600" ]; then
		echo "Solr wait timeout of 600s exceeded"
		exit 3;
	fi

	if [ "$check_result" -eq "4" ]; then
		hard_fails=$(( hard_fails + 1 ))
		if [ "$hard_fails" -gt 3 ]; then
			echo "Failed recovering after restarting tomcat 3 times"
			exit 4;
		fi
		echo "Hard failure loading index, restarting tomcat8 to try to recover - retry number $hard_fails"
		systemctl restart tomcat8
	fi

	echo "Solr not ready, retrying in 30s..."
	sleep 30
	check_result="0"
	/usr/local/bin/solr_check_instance.sh "$instance" || check_result="$?"
done
