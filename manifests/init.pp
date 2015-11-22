#
# = Class: Couchbase
#
# This module manages couchbase
#
#
# == Parameters
#
# [*ensure*]
#   Type: string, default: 'present'
#   Manages package installation and class resources. Possible values:
#   * 'present' - Install package, ensure files are present (default)
#   * 'absent'  - Stop service and remove package and managed files
#
# [*package*]
#   Type: string, default on $::osfamily basis
#   Manages the name of the package.
#
# [*version*]
#   Type: string, default: undef
#   If this value is set, the defined version of package is installed.
#   Possible values are:
#   * 'x.y.z' - Specific version
#   * latest  - Latest available
#
# [*service*]
#   Type: string, defaults on $::osfamily basis
#   Name of the backup (or archive) service. Defaults are provided on
#   $::osfamily basis.
#
# [*status*]
#   Type: string, default: 'enabled'
#   Define the provided service status. Available values affect both the
#   ensure and the enable service arguments:
#   * 'enabled':     ensure => running, enable => true
#   * 'disabled':    ensure => stopped, enable => false
#   * 'running':     ensure => running, enable => undef
#   * 'stopped':     ensure => stopped, enable => undef
#   * 'activated':   ensure => undef  , enable => true
#   * 'deactivated': ensure => undef  , enable => false
#   * 'unmanaged':   ensure => undef  , enable => undef
#
# [*dependency_class*]
#   Type: string, default: tsm::dependency
#   Name of a class that contains resources needed by this module but provided
#   by external modules. Set to undef to not include any dependency class.
#
# [*my_class*]
#   Type: string, default: undef
#   Name of a custom class to autoload to manage module's customizations
#
# [*noops*]
#   Type: boolean, default: undef
#   Set noop metaparameter to true for all the resources managed by the module.
#   If true no real change is done is done by the module on the system.
#
class couchbase (
  $ensure                       = present,
  $package                      = $::couchbase::params::package,
  $version                      = undef,
  $service                      = $::couchbase::params::service,
  $status                       = 'enabled',
  $file_cbcnf_path              = $::couchbase::params::file_cbcnf_path,
  $file_cbcnf_template          = 'couchbase/cb.cnf.erb',
  $admin_username               = 'secret',
  $admin_password               = 'secret',
  $cluster_ip                   = '',
  $dependency_class             = $::couchbase::dependency_class,
  $my_class                     = undef,
  $noops                        = undef,
  ) inherits couchbase::params {

  ### Input parameters validation
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent')
  validate_string($package)
  validate_string($version)
  validate_string($service)
  validate_re($status,  ['enabled','disabled','running','stopped','activated','deactivated','unmanaged'], 'Valid values are: enabled, disabled, running, stopped, activated, deacti
vated and unmanaged')

  ### Internal variables (that map class parameters)
  if $ensure == 'present' {
    $package_ensure = $version ? {
      ''      => 'present',
      default => $version,
    }
    $service_enable = $status ? {
      'enabled'     => true,
      'disabled'    => false,
      'running'     => undef,
      'stopped'     => undef,
      'activated'   => true,
      'deactivated' => false,
      'unmanaged'   => undef,
    }
    $service_ensure = $status ? {
      'enabled'     => 'running',
      'disabled'    => 'stopped',
      'running'     => 'running',
      'stopped'     => 'stopped',
      'activated'   => undef,
      'deactivated' => undef,
      'unmanaged'   => undef,
    }
    $file_ensure = present
  } else {
    $package_ensure = 'absent'
    $backup_service_enable = undef
    $backup_service_ensure = stopped
    $archive_service_enable = undef
    $archive_service_ensure = stopped
    $file_ensure    = absent
  }

  ### Extra classes
  if $dependency_class { include $dependency_class }
  if $my_class         { include $my_class         }

  # get correct package
  package { 'couchbase-server' :
    ensure => $package_ensure,
    name   => $package,
    noop   => $noops,
  }

  service { 'couchbase-server':
    ensure  => $service_ensure,
    name    => $service,
    enable  => $service_enable,
    require => Package['couchbase-server'],
    noop    => $noops,
  }

  file { 'cb.cnf':
    ensure  => file,
    path    => $file_cbcnf_path,
    content => template($file_cbcnf_template),
    require => Package['couchbase-server'],
    noop    => $noops,
  }

  Couchbucket {
    require => [
      File['cb.cnf'],
      Service['couchbase-server'],
    ],
  }

  # join cluster
  if $cluster_ip != '' {
    exec { 'join_couchbase_cluster':
      command => "/opt/couchbase/bin/couchbase-cli server-add -c ${cluster_ip}:8091 --server-add=${::ipaddress}:8091 -u ${admin_username} -p ${admin_password}",
      unless  => "/opt/couchbase/bin/couchbase-cli server-list -c ${::ipaddress}:8091 >/dev/null -u ${admin_username} -p ${admin_password}",
      require => Service['couchbase-server'],
    }
  }

  # autocreate buckets
  $couchbase_buckets = hiera_hash('couchbase::buckets', {})
  create_resources(couchbucket, $couchbase_buckets)

}
# vi:syntax=puppet:filetype=puppet:ts=4:et:nowrap:
