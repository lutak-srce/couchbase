Puppet::Type.newtype(:couchbucket) do
@doc = "Manages the Couchbase bucket

A typical rule will look like this:

couchbucket { 'example':
  ensure     => present,
  port       => 21212,
  ramquotamb => 128,
}

"

  desc 'The Couchbase bucket'

  ensurable

  newparam(:name) do
    desc 'The name of the bucket.'
    isnamevar
  end

  newproperty(:type) do
    desc 'Type of the bucket, so far ony Memcached and Couchbase are supported.'
    newvalue(:memcached)
    newvalue(:couchbase)
    defaultto :memcached
  end

  newproperty(:auth) do
    desc 'type of authorization to be enabled for the new bucket.'
    newvalue(:none)
    newvalue(:sasl)
    defaultto :none
  end

  newproperty(:password) do
    desc 'Password for the sasl authentication.'
    defaultto ''
  end

  newproperty(:flush) do
    desc 'Enables the "flush all" functionality on the specified bucket.'
    newvalue(:true)
    newvalue(:false)
    defaultto :false
  end

  newproperty(:port) do
    desc 'Dedicated port (supports ASCII protocol and is auth-less).'
    validate do |value|
      unless value.chomp.empty?
        raise ArgumentError, "%s is not a valid port." % value unless value.to_i >= 0 and value.to_i <= 65535
      end
    end
  end

  newproperty(:replica_index) do
    desc 'Enable replica indexes for replica bucket data.'
    newvalue(:true)
    newvalue(:false)
    defaultto :true
  end

  newproperty(:replica_number) do
    desc 'Number of replica (backup) copies.'
    validate do |value|
      raise ArgumentError, "%s is not a valid replicaNumber." % value.to_i if value.to_i < 0 or value.to_i > 3
    end
    defaultto '1'
  end

  newproperty(:threads_number) do
    desc 'Number of concurrent readers and writers for the data bucket.'
    validate do |value|
      raise ArgumentError, "%s is not a valid threadsNumber." % value unless value.to_i >= 2 and value.to_i <= 8
    end
    defaultto '3'
  end

  newproperty(:ramquotamb) do
    desc 'Per Node RAM Quota. Total RAM used by bucket is per-node-quota x nodes number.'
    defaultto '64'
  end

  newproperty(:parallel_compaction) do
    desc 'Whether database and view files on disk can be compacted simultaneously.'
    newvalue(:true)
    newvalue(:false)
    defaultto :false
  end

end
