class ss_solr::service inherits ss_solr {

	service { 'tomcat8':
		ensure => 'running',
		enable => true,
	}

}
