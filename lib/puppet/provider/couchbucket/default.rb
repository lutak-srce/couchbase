require 'rubygems'
require 'net/http'
require 'json'
require 'pathname'

Puppet::Type.type(:couchbucket).provide(:couchbucket) do
  desc 'Support for managing the Couchbase bucket'

  @@couchbase_host = '127.0.0.1'
  @@couchbase_port = '8091'
  @@couchbase_user = nil
  @@couchbase_pass = nil

  mk_resource_methods

  def self.instances
    buckets = []

    JSON.parse(restapirequest(Net::HTTP::Get.new('/pools/default/buckets'))).each do |rest_bucket|
      buckets << new(
        :name                => rest_bucket['name'],
        :ensure              => :present,
        :type                => rest_bucket['bucketType'],
        :auth                => rest_bucket['authType'],
        :password            => rest_bucket['saslPassword'],
        :flush               => rest_bucket['controllers']['flush'].nil? ? 'false' : 'true',
        :port                => rest_bucket['proxyPort'].to_s,
        :replica_index       => rest_bucket['replicaIndex'].to_s,
        :replica_number      => rest_bucket['replicaNumber'].to_s,
        :threads_number      => rest_bucket['threadsNumber'].to_s,
        :ramquotamb          => (rest_bucket['quota']['ram'] / 1024 / 1024).to_s,
        :parallel_compaction => rest_bucket['autoCompactionSettings'].to_s == 'true' ? 'true' : 'false'
      )
    end

    # return list of present buckets
    buckets
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  # read onnection info from file
  def self.read_defaults
    defaults_file = '/opt/couchbase/.cb.cnf'
    if File.file?(defaults_file)
      File.readlines(defaults_file).each do |line|
        values = line.split("=")
        case values[0]
        when 'CB_REST_USERNAME'
          @@couchbase_user = values[1].chomp
        when 'CB_REST_PASSWORD'
          @@couchbase_pass = values[1].chomp
        when 'CB_REST_HOST'
          @@couchbase_host = values[1].chomp
        when 'CB_REST_PORT'
          @@couchbase_port = values[1].chomp
        end
      end
    end
  end
  
  def read_defaults
    self.class.read_defaults
  end

  # method used for querying Couchbase REST API
  def self.restapirequest(request)
    read_defaults

    # connect to standard couchbase IP:PORT
    http = Net::HTTP.new(@@couchbase_host,@@couchbase_port)

    # if env variables are set, use them for HTTP basic auth
    request.basic_auth @@couchbase_user, @@couchbase_pass unless @@couchbase_user.nil? or @@couchbase_pass.nil?

    # make REST call
    resp, data = http.request(request)

    # return data
    data
  end

  def restapirequest(request)
    self.class.restapirequest(request)
  end

  # bucketType can be specified only at creation time
  def type=(value)
    self.destroy
    self.create
  end

  # authType can be specified only at creation time
  def auth=(value)
    self.destroy
    self.create
  end

  # saslPassword
  def password=(value)
    self.create
  end

  # flushEnabled
  def flush=(value)
    self.create
  end

  # proxyPort can be specified only at creation time
  def port=(value)
    self.destroy
    self.create
  end

  # replicaIndex
  def replica_index=(value)
    self.create
  end

  # replicaNumber
  def replica_number=(value)
    self.create
  end

  # threadsNumber
  def threads_number=(value)
    self.create
  end

  # ramQuotaMB
  def ramquotamb=(value)
    # memcached type buckets cannot edit ramsize, but have to be
    # destroyed and recreated
    self.destroy if @resource[:type] == :memcached
    self.create
    # update @property_hash
    @property_hash[:ramquotamb]=(value)
  end

  # parallelDBAndViewCompaction
  def parallel_compaction=(value)
    self.create
  end

  def create
    # create new bucket (or edit existing one)
    # POST /pools/default/buckets
    
    # if resource already exist - we are modifying it (different REST location)
    bucket  = ''
    bucket += '/' + @resource[:name] if @property_hash[:name] == @resource[:name] and @property_hash[:ensure] == :present

    request = Net::HTTP::Post.new('/pools/default/buckets' + bucket)
    
    # set POST params
    request.set_form_data({
      "name"                        => @resource[:name],
      "bucketType"                  => @resource[:type].to_s,
      "authType"                    => @resource[:auth].to_s,
      "saslPassword"                => @resource[:password],
      "flushEnabled"                => @resource[:flush].to_s == 'true' ? 1 : 0,
      "proxyPort"                   => @resource[:port].to_i,
      "replicaIndex"                => @resource[:replica_index].to_s == 'true' ? 1 : 0,
      "replicaNumber"               => @resource[:replica_number].to_i,
      "threadsNumber"               => @resource[:threads_number].to_i,
      "ramQuotaMB"                  => @resource[:ramquotamb].to_i,
      "parallelDBAndViewCompaction" => @resource[:parallel_compaction].to_s
    })

    # make REST call
    restapirequest(request)

    # update @property_hash
    @property_hash[:ensure] = :present
  end

  def destroy
    # remove bucket from Couchbase
    # DELETE /pools/default/buckets/bucket_name
    restapirequest(Net::HTTP::Delete.new('/pools/default/buckets/' + @resource[:name]))
    
    # update @property_hash
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

end
