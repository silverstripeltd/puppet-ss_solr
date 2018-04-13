class solr::service inherits solr {

	service { 'tomcat8':
		ensure => 'running',
		enable => true,
	}

}
