class ss_solr::install inherits ss_solr {
	if ss_solr::multithreaded{
			$threads = $facts['processors']['count']
	} else {
			$threads = 1
	}
	if $facts['lsbdistcodename'] == 'jessie' {
		notice("Your system is not compatible with this Puppet6 implementation. Please use the Puppet3 version.")
	} else {
		file { ['/usr/java', '/usr/share', '/usr/share/tomcat8', '/etc/tomcat8/']:
			ensure => 'directory',
			mode => '0755',
			owner => 'root',
			group => 'root',
		}
		file { '/usr/share/tomcat8/lib':
			ensure => 'directory',
			mode => '0755',
			owner => 'tomcat8',
			group => 'tomcat8',
		}
		package{"jq":
			ensure => installed
		}
		# Install default jre to enable us to use update-alternatives correctly
		package{"libecj-java":
			ensure => installed
		}
		-> package{"default-jre":
			ensure => installed
		}

		# Install latest java 8 by unpacking an archive from S3.
		$install_path = '/usr/java'
		$longversion = "jre1.8.0_261"
		$version = "8u261"
		$priority = 1000000 + 8 * 100000 + 261
		archive { "/tmp/jre-8u261-linux-x64.tar.gz":
			source       => "https://ss-packages.s3.amazonaws.com/debian-buster/jre-8u261-linux-x64.tar.gz",
			proxy_server => $ss_solr::http_proxy,
			proxy_type   => 'http',
			cleanup      => true,
			extract      => true,
			extract_path => $install_path,
			creates      => "${install_path}/${longversion}",
			require      => File['/usr/java']
		}
		-> file{"${install_path}/${longversion}":
			ensure => 'directory'
		}

		Exec {
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => File["${install_path}/${longversion}"],
    unless  => "update-alternatives --display java | grep -e ${install_path}/${longversion}/bin/java.*${priority}\$"
		}
		exec { "add java alternative ${version}":
			command => "update-alternatives --install /usr/bin/java java ${install_path}/${longversion}/bin/java ${priority} \
               --slave /usr/share/man/man1/java.1 java.1 ${install_path}/${longversion}/man/man1/java.1;
                update-alternatives --install /usr/bin/javaws javaws ${install_path}/${longversion}/bin/javaws ${priority} \
                 --slave /usr/share/man/man1/javaws.1 javaws.1 ${install_path}/${longversion}/man/man1/javaws.1;
                update-alternatives --install /usr/bin/jcontrol jcontrol ${install_path}/${longversion}/bin/jcontrol ${priority};
                update-alternatives --install /usr/bin/jjs jjs ${install_path}/${longversion}/bin/jjs${priority} \
                 --slave /usr/share/man/man1/jjs.1 jjs.1 ${install_path}/${longversion}/man/man1/jjs.1;
                update-alternatives --install /usr/bin/keytool keytool ${install_path}/${longversion}/bin/keytool ${priority} \
                 --slave /usr/share/man/man1/keytool.1 keytool.1 ${install_path}/${longversion}/man/man1/keytool.1;
                update-alternatives --install /usr/bin/orbd orbd ${install_path}/${longversion}/bin/orbd ${priority} \
                 --slave /usr/share/man/man1/orbd.1 orbd.1 ${install_path}/${longversion}/man/man1/orbd.1;
                update-alternatives --install /usr/bin/pack200 pack200 ${install_path}/${longversion}/bin/pack200 ${priority} \
                 --slave /usr/share/man/man1/pack200.1 pack200.1 ${install_path}/${longversion}/man/man1/pack200.1;
                update-alternatives --install /usr/bin/policytool policytool ${install_path}/${longversion}/bin/policytool ${priority} \
                 --slave /usr/share/man/man1/policytool.1 policytool.1 ${install_path}/${longversion}/man/man1/policytool.1;
                update-alternatives --install /usr/bin/rmid rmid ${install_path}/${longversion}/bin/rmid ${priority} \
                 --slave /usr/share/man/man1/rmid.1 rmid.1 ${install_path}/${longversion}/man/man1/rmid.1;
                update-alternatives --install /usr/bin/rmiregistry rmiregistry ${install_path}/${longversion}/bin/rmiregistry ${priority} \
                 --slave /usr/share/man/man1/rmiregistry.1 rmiregistry.1 ${install_path}/${longversion}/man/man1/rmiregistry.1;
                update-alternatives --install /usr/bin/servertool servertool ${install_path}/${longversion}/bin/servertool ${priority} \
                 --slave /usr/share/man/man1/servertool.1 servertool.1 ${install_path}/${longversion}/man/man1/servertool.1;
                update-alternatives --install /usr/bin/tnameserv tnameserv ${install_path}/${longversion}/bin/tnameserv ${priority} \
                 --slave /usr/share/man/man1/tnameserv.1 tnameserv.1 ${install_path}/${longversion}/man/man1/tnameserv.1;
                update-alternatives --install /usr/bin/unpack200 unpack200 ${install_path}/${longversion}/bin/unpack200 ${priority} \
                 --slave /usr/share/man/man1/unpack200.1 unpack200.1 ${install_path}/${longversion}/man/man1/unpack200.1"
		}
		# mimic RPM behaviour (required for JAVA_HOME in tomcat config)
		-> file { "${install_path}/default":
			ensure => link,
			target => "${install_path}/${longversion}"
		}

		# Install tomcat packages downloaded from S3 via provider dpkg (requires libecj-java)
		archive { "/tmp/libtomcat8-java_8.0.14-1+deb8u17_all.deb":
			source       => "https://ss-packages.s3.amazonaws.com/debian-buster/libtomcat8-java_8.0.14-1%2Bdeb8u17_all.deb",
			proxy_server => $ss_solr::http_proxy,
			proxy_type   => 'http',
		}
		-> package{"libtomcat8-java":
				ensure => present,
				provider => 'dpkg',
				source => "/tmp/libtomcat8-java_8.0.14-1+deb8u17_all.deb"
		}
		archive { "/tmp/tomcat8-common_8.0.14-1+deb8u17_all.deb":
			source       => "https://ss-packages.s3.amazonaws.com/debian-buster/tomcat8-common_8.0.14-1%2Bdeb8u17_all.deb",
			proxy_server => $ss_solr::http_proxy,
			proxy_type   => 'http',
		}
		-> package{"tomcat8-common":
				ensure => present,
				provider => 'dpkg',
				source => "/tmp/tomcat8-common_8.0.14-1+deb8u17_all.deb"
		}
		archive { "/tmp/tomcat8-admin_8.0.14-1+deb8u17_all.deb":
			source       => "https://ss-packages.s3.amazonaws.com/debian-buster/tomcat8-admin_8.0.14-1%2Bdeb8u17_all.deb",
			proxy_server => $ss_solr::http_proxy,
			proxy_type   => 'http',
		}
		-> package{"tomcat8-admin":
				ensure => present,
				provider => 'dpkg',
				source => "/tmp/tomcat8-admin_8.0.14-1+deb8u17_all.deb"
		}
		archive { "/tmp/tomcat8_8.0.14-1+deb8u17_all.deb":
			source       => "https://ss-packages.s3.amazonaws.com/debian-buster/tomcat8_8.0.14-1%2Bdeb8u17_all.deb",
			proxy_server => $ss_solr::http_proxy,
			proxy_type   => 'http',
		}
		-> package{"tomcat8":
				ensure => present,
				provider => 'dpkg',
				source => "/tmp/tomcat8_8.0.14-1+deb8u17_all.deb"
		}
	}
	archive { "/tmp/solr-${ss_solr::solr_version}.tgz":
		provider     => 'curl',
		source       => "https://ss-packages.s3.amazonaws.com/solr-${ss_solr::solr_version}.tgz",
		cleanup      => true,
		extract      => true,
		proxy_server => $ss_solr::http_proxy,
		extract_path => '/opt',
		creates      => "/opt/solr-${ss_solr::solr_version}/README.txt",
	}
	-> exec { "cp /opt/solr-${ss_solr::solr_version}/example/lib/ext/* /usr/share/tomcat8/lib/ && chown tomcat8:tomcat8 -R /usr/share/tomcat8/lib":
		unless => 'ls /usr/share/tomcat8/lib/slf4j-*.jar',
		notify => Service['tomcat8'],
	}

	file { '/var/lib/tomcat8/conf/server.xml':
		ensure => 'present',
		content => template('ss_solr/server.xml.erb'),
		path => '/var/lib/tomcat8/conf/server.xml'
	}
	-> file { '/var/lib/solr':
		ensure => 'directory',
		mode => '0755',
		owner => 'root',
		group => 'root',
	}
	-> file { '/var/lib/solr/accounts.d':
		ensure => 'directory',
		mode => '0700',
		owner => 'www-data',
		group => 'www-data',
	}
	-> exec { "cp -fr /opt/solr-${ss_solr::solr_version}/dist/solr-${ss_solr::solr_version}.war /var/lib/solr/solr4.war":
		creates => '/var/lib/solr/solr4.war',
	}
	-> file { '/var/log/solr':
		ensure => 'directory',
		mode => '0755',
		owner => 'tomcat8',
		group => 'tomcat8',
	}
	-> file { '/usr/local/bin/solr_reload_instance.sh':
		source => 'puppet:///modules/ss_solr/solr_reload_instance.sh',
		owner => 'root',
		group => 'root',
		mode => '0755',
	}
	-> file { '/usr/local/bin/solr_commit_instance.sh':
		source => 'puppet:///modules/ss_solr/solr_commit_instance.sh',
		owner => 'root',
		group => 'root',
		mode => '0755',
	}
 	-> file { '/usr/local/bin/solr_check_instance.sh':
		source => 'puppet:///modules/ss_solr/solr_check_instance.sh',
		owner => 'root',
		group => 'root',
		mode => '0755',
	}
	-> file { '/usr/local/bin/solr_ensure_instance.sh':
		source => 'puppet:///modules/ss_solr/solr_ensure_instance.sh',
		owner => 'root',
		group => 'root',
		mode => '0755',
	}
	-> file { '/usr/local/bin/solr_fixperms_instance.sh':
		source => 'puppet:///modules/ss_solr/solr_fixperms_instance.sh',
		owner => 'root',
		group => 'root',
		mode => '0755',
	}
}
