#
# = Class: couchbase::params
#
# This module contains defaults for postfix modules
#
class couchbase::params {

  $ensure           = 'present'
  $version          = undef
  $status           = 'enabled'
  $autorestart      = true
  $dependency_class = 'couchbase::dependency'
  $my_class         = undef

  # install package depending on major version
  case $::osfamily {
    default: {}
    /(RedHat|redhat|amazon)/: {
      $package         = 'couchbase-server'
      $service         = 'couchbase-server'
      $file_cbcnf_path = '/opt/couchbase/.cb.cnf'
    }
    /(Debian|debian)/: {
      $package         = 'couchbase-server'
      $service         = 'couchbase-server'
      $file_cbcnf_path = '/opt/couchbase/.cb.cnf'
    }
  }

}
