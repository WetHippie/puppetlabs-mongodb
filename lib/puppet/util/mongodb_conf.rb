require 'yaml'
require 'json'

module Puppet
  module Util
    class MongodbConfLoader
      @@mongo_conf_file = '/etc/mongod.conf'

      def self.get_mongo_conf
        file = get_mongod_conf_file
        # The mongo conf is probably a key-value store, even though 2.6 is
        # supposed to use YAML, because the config template is applied
        # based on $::mongodb::globals::version which is the user will not
        # necessarily set. This attempts to get the port from both types of
        # config files.
        config = YAML.load_file(file)
        config_hash = Hash.new
        if config.kind_of?(Hash) # Using a valid YAML file for mongo 2.6
          config_hash['bindip'] = config['net.bindIp']
          config_hash['port'] = config['net.port']
          config_hash['ipv6'] = config['net.ipv6']
          config_hash['allowInvalidHostnames'] = config['net.ssl.allowInvalidHostnames']
          config_hash['ssl'] = config['net.ssl.mode']
          config_hash['sslcert'] = config['net.ssl.PEMKeyFile']
          config_hash['sslca'] = config['net.ssl.CAFile']
          config_hash['auth'] = config['security.authorization']
          config_hash['shardsvr'] = config['sharding.clusterRole']
          config_hash['confsvr'] = config['sharding.clusterRole']
        else # It has to be a key-value config file
          config = {}
          File.readlines(file).collect do |line|
            k,v = line.split('=')
            config[k.rstrip] = v.lstrip.chomp if k and v
          end
          config_hash['bindip'] = config['bind_ip']
          config_hash['port'] = config['port']
          config_hash['ipv6'] = config['ipv6']
          config_hash['ssl'] = config['sslOnNormalPorts']
          config_hash['allowInvalidHostnames'] = config['allowInvalidHostnames']
          config_hash['sslcert'] = config['sslPEMKeyFile']
          config_hash['sslca'] = config['sslCAFile']
          config_hash['auth'] = config['auth']
          config_hash['shardsvr'] = config['shardsvr']
          config_hash['confsvr'] = config['confsvr']
        end

        config_hash
      end

      def self.get_mongod_conf_file
        if File.exists? @@mongo_conf_file
          file = @@mongo_conf_file
        else
          file = '/etc/mongodb.conf'
        end
        file
      end

      def self.set_mongod_conf_file(value)
        @@mongo_conf_file = value
      end
    end
  end
end
