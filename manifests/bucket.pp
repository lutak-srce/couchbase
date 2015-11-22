# Define: couchbase::bucket
#
# This define adds couchbase bucket
#
define couchbase::bucket (
  $proxyPort,
  $bucket      = $title,
  $bucketType  = 'memcached',
  $authType    = 'none',
  $ramQuota    = '100',
  $numReplicas = '0',
  $couch_cli   = '/opt/couchbase/bin/couchbase-cli',
  $server_ip   = '127.0.0.1',
  $server_port = '8091',
  $server_user = $couchbase::server_user,
  $server_pass = $couchbase::server_pass,
) {
  require couchbase

  exec { "couch_create_bucket_${bucket}":
    command => "${couch_cli} bucket-create --bucket=${bucket} \
                --bucket-type=${bucketType} --bucket-port=${proxyPort} \
                --bucket-ramsize=${ramQuota} --bucket-replica=${numReplicas} \
                -u ${server_user} -p ${server_pass} -c ${server_ip}:${server_port}",
    unless  => "${couch_cli} bucket-list -c ${server_ip}:${server_port} | /bin/grep ^${bucket}",
  }
}
# TODO: rewrite to native custom type
