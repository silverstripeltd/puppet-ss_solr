define ss_solr::proxy_config(
	$accounts_d = '/var/lib/solr/accounts.d',
	$solrconfigs = '/sites/solrproxy/solrconfigs',
	$solrcores = '/var/lib/solr',
	$backend = 'http://localhost:8080',
	$drop_user_solrconfig = true,
){
	file { $name:
		mode => "0755",
		owner => "root",
		group => "root",
		content => template("ss_solr/solrproxy_configuration.erb"),
	}

}
