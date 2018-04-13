define ss_solr::instance(
	$ensure = 'present',
	$auth_password,
	$auth_user,
	$solr_auto_commit_max_sec = undef,
	$solr_auto_soft_commit_max_sec = undef,
	$solr_default_spellchecker_field = undef,
	$solr_config_override = undef,
){

	# Salt should really be random, but as long as auth_password is random, we're probably OK
	$crypted_password = ht_crypt($auth_password, '0z')

	file { "/var/lib/solr/accounts.d/${auth_user}":
		ensure => $ensure,
		owner => "www-data", group => "www-data", mode => 0600,
		content => "${crypted_password}",
	}

	file { "/var/lib/solr/${auth_user}v4":
		ensure => $ensure ? { 'present' => 'directory', default => $ensure },
		force => true,
		owner => "www-data", group => "tomcat8", mode => 0775
	}

	file { "/var/lib/solr/${auth_user}v4/solr.xml":
		ensure => $ensure,
		owner => "www-data", group => "tomcat8", mode => 0664,

		content => "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><solr></solr>\n"
	}

	# Instance-supplied values take precedence over solr server settings ("default").
	if $solr_auto_commit_max_sec {
		$auto_commit = $solr_auto_commit_max_sec * 1000
	} elsif $solr_auto_commit_max_sec_default {
		$auto_commit = $solr_auto_commit_max_sec_default * 1000
	}
	if $solr_auto_soft_commit_max_sec {
		$auto_soft_commit = $solr_auto_soft_commit_max_sec * 1000
	} elsif $solr_auto_soft_commit_max_sec_default {
		$auto_soft_commit = $solr_auto_soft_commit_max_sec_default * 1000
	}
	if $solr_config_override {
		$config_template = template($solr_config_override)
	} else {
		$config_template = template('ss_solr/solrconfig.xml.erb')
	}
	file { "/var/lib/solr/${auth_user}v4/solrconfig.xml":
		ensure => $ensure,
		owner => "www-data", group => "tomcat8", mode => 0664,
		content => $config_template,
	}~>
	exec { "Reload instance cores for ${auth_user}":
		refreshonly => true,
		command => "/usr/local/bin/solr_reload_instance.sh ${auth_user}",
		unless => "[ ! -f \"/usr/local/bin/solr_reload_instance.sh\" -o ! -f \"/etc/tomcat8/Catalina/localhost/${auth_user}v4.xml\" ]",
		path => "/bin:/usr/bin:/usr/sbin",
	}

	file { "/etc/tomcat8/Catalina/localhost/${auth_user}v4.xml":
		ensure => $ensure,
		owner => "root", group => "root", mode => 0644,

		content => "
			<Context docBase=\"/var/lib/solr/solr4.war\" debug=\"0\" privileged=\"false\" allowLinking=\"true\" crossContext=\"true\">
				<Environment name=\"solr/home\" type=\"java.lang.String\" value=\"/var/lib/solr/${auth_user}v4\" override=\"true\" />
			</Context>"
	}
}

