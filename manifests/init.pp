class ss_solr(
	$java_heap_mb = 8192,
	$java_metaspace_mb = undef,
	$java_allow_unsafe_resource_loading = false,
	$solr_version = '4.5.1',
	$password_manager = undef,
	$password_status = undef,
	$user_manager = undef,
	$user_status = undef,
) {

	# e.g. '8', '7u80', see https://github.com/antoineco/aco-oracle_java#a-couple-of-examples
	validate_numeric($java_heap_mb)
	if $java_metaspace_mb {
		validate_numeric($java_metaspace_mb)
	}

	# Please upload the required version to S3 first. For example for '4.10.4', do:
	# aws s3 cp ~/Downloads/solr-4.10.4.tgz s3://ss-packages/solr-4.10.4.tgz --profile silverstripe
	validate_string($solr_version)

	class { 'ss_solr::install': }
	-> class { 'ss_solr::config': }
	~> class { 'ss_solr::service': }
}
