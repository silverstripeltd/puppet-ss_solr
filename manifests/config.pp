class ss_solr::config inherits ss_solr {

	file { '/usr/share/tomcat8/lib/log4j.properties':
		source => 'puppet:///modules/solr/log4j.properties',
		owner => 'tomcat8',
		group => 'tomcat8',
		mode => 0644,
	}

	$heap_mb = $ss_solr::java_heap_mb
	$metaspace_mb = $ss_solr::java_metaspace_mb
	file { '/etc/default/tomcat8':
		content => template('solr/tomcat_defaults.erb'),
		owner => 'tomcat8',
		group => 'tomcat8',
		mode => 0644,
	}

	file { '/etc/tomcat8/tomcat-users.xml':
		content => template('solr/tomcat-users.xml.erb'),
		owner => 'root',
		group => 'tomcat8',
		mode => 0640,
	}

	$password_manager = $ss_solr::password_manager
	$password_status = $ss_solr::password_status
	$user_manager = $ss_solr::user_manager
	$user_status = $ss_solr::password_status
	file { '/etc/cron.d/solr-log-purge':
		content => "0 3 * * * root find /var/log/solr -type f -mtime +30 -delete 2>&1 | logger -t solr-log-purge\n",
		owner => 'root',
		group => 'root',
		mode => 0640,
	}
}

