#!/bin/bash
# Fix file ownership on cores.

set -euo pipefail

if [ "$#" -lt "1" ]; then
	echo "Cowardly refusing to reload all cores on this server. Please specify an instance as the first param."
	exit 2
fi

instance="${1}v4"
target="*/${instance}/*"

for core in $(find /var/lib/solr -maxdepth 2 -mindepth 2 -path "$target" -type d -not -name logs); do
	index=$(basename $core)

	wwwdata="( -not -user www-data -o -not -group tomcat8 )"
	wwwdatafix='echo "Fixing {}"; chown www-data:tomcat8 {}'
	find "/var/lib/solr/$instance/$index" -maxdepth 0 $wwwdata -exec bash -c "$wwwdatafix" \;
	find "/var/lib/solr/$instance/$index/conf" $wwwdata -exec bash -c "$wwwdatafix" \;
	find "/var/lib/solr/$instance/solrconfig.xml" -maxdepth 0 $wwwdata -exec bash -c "$wwwdatafix" \;
	find "/var/lib/solr/$instance/solr.xml" -maxdepth 0 $wwwdata -exec bash -c "$wwwdatafix" \;

	tomcat8="( -not -user tomcat8 -o -not -group tomcat8 )"
	tomcat8fix='echo "Fixing {}"; chown tomcat8:tomcat8 {}'
	find "/var/lib/solr/$instance/$index/core.properties" -maxdepth 0 $tomcat8 -exec bash -c "$tomcat8fix" \;
	find "/var/lib/solr/$instance/$index/data" $tomcat8 -exec bash -c "$tomcat8fix" \;
done
