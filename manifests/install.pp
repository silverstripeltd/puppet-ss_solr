class solr::install inherits solr {

	Exec {
		path => "/bin:/usr/bin:/usr/sbin",
	}

	class { 'oracle_java':
		version => $solr::java_version,
		add_alternative => true,
		proxy_server => $solr::http_proxy,
		proxy_type => 'http',
	}->
	package { ['tomcat8', 'tomcat8-admin']:
		ensure => 'present',
	}->
	archive { "/tmp/solr-$solr::solr_version.tgz":
		provider     => 'curl',
		source       => "https://ss-packages.s3.amazonaws.com/solr-$solr::solr_version.tgz",
		cleanup      => true,
		extract      => true,
		extract_path => "/opt",
		creates      => "/opt/solr-$solr::solr_version/README.txt",
	}->
	exec { "cp /opt/solr-$solr::solr_version/example/lib/ext/* /usr/share/tomcat8/lib/ && chown tomcat8:tomcat8 -R /usr/share/tomcat8/lib":
		unless => 'ls /usr/share/tomcat8/lib/slf4j-*.jar',
	}->
	file { '/var/lib/solr':
		ensure => 'directory',
		mode => 0755,
		owner => "root",
		group => "root",
	}->
	file { "/var/lib/solr/accounts.d":
		ensure => "directory",
		mode => 0700,
		owner => "www-data",
		group => "www-data",
	}->
	exec { "cp -fr /opt/solr-$solr::solr_version/dist/solr-$solr::solr_version.war /var/lib/solr/solr4.war":
		creates => '/var/lib/solr/solr4.war',
	}->
	file { '/var/log/solr':
		ensure => 'directory',
		mode => 0755,
		owner => "tomcat8",
		group => "tomcat8",
	}->
	file { '/usr/local/bin/solr_reload_instance.sh':
		source => 'puppet:///modules/solr/solr_reload_instance.sh',
		owner => 'root',
		group => 'root',
		mode => 0755,
	}->
	file { '/usr/local/bin/solr_commit_instance.sh':
		source => 'puppet:///modules/solr/solr_commit_instance.sh',
		owner => 'root',
		group => 'root',
		mode => 0755,
	}

}
