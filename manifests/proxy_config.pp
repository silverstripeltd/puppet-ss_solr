define ss_solr::proxy_config {
	$accounts_d = '/var/lib/solr/accounts.d'
	$solrconfigs = '/sites/solrproxy/solrconfigs'
	$solrcores = '/var/lib/solr'
	$backend = 'http://localhost:8080'

	file { $name:
		mode => 0755,
		owner => "root",
		group => "root",
		content => template("solr/solrproxy_configuration.erb"),
	}

}
