require File.expand_path(File.join(File.dirname(__FILE__),'..','util','mongodb_conf'))

require 'yaml'
require 'json'
class Puppet::Provider::Mongodb < Puppet::Provider

  # Without initvars commands won't work.
  initvars
  commands :mongo => 'mongo'

  # Optional defaults file
  def self.mongorc_file
    if File.file?("#{Facter.value(:root_home)}/.mongorc.js")
      "load('#{Facter.value(:root_home)}/.mongorc.js'); "
    else
      nil
    end
  end

  def mongorc_file
    self.class.mongorc_file
  end

  def self.get_mongo_conf
    Puppet::Util::MongodbConfLoader.get_mongo_conf
  end

  def self.ipv6_is_enabled(config=nil)
    config ||= get_mongo_conf
    config['ipv6']
  end

  def self.ssl_is_enabled(config=nil)
    config ||= get_mongo_conf
    ssl_mode = config.fetch('ssl')
    ssl_mode.nil? ? false : ssl_mode != 'disabled'
  end

  def self.ssl_invalid_hostnames(config=nil)
    config ||= get_mongo_conf
    config['allowInvalidHostnames']
  end

  def self.mongo_cmd(db, host, cmd, ignore_auth = false)
    config = get_mongo_conf

    args = [db, '--quiet', '--host', host]
    args.push('--ipv6') if ipv6_is_enabled(config)
    args.push('--sslAllowInvalidHostnames') if ssl_invalid_hostnames(config)

    if ssl_is_enabled(config)
      args.push('--ssl')
      args += ['--sslPEMKeyFile', config['sslcert']]

      ssl_ca = config['sslca']
      unless ssl_ca.nil?
        args += ['--sslCAFile', ssl_ca]
      end
    end

    if ignore_auth
       Puppet.debug "MongoDB command is ignoring putting in authentication command options"
    elsif auth_enabled(config)
      Puppet.debug "Mongo DB has auth enabled. Accessing with username: #{@@admin_username} and password #{@@admin_password}"

      args.push('--username')
      args.push(@@admin_username)
      args.push('--password')
      args.push(@@admin_password)
    else
      Puppet.debug "MongoDB command does not require authentication"
    end

    args += ['--eval', cmd]
    mongo(args)
  end

  def self.get_conn_string
    config = get_mongo_conf
    bindip = config.fetch('bindip')
    if bindip
      first_ip_in_list = bindip.split(',').first
      case first_ip_in_list
      when '0.0.0.0'
        ip_real = '127.0.0.1'
      when /\[?::0\]?/
        ip_real = '::1'
      else
        ip_real = first_ip_in_list
      end
    end

    port = config.fetch('port')
    shardsvr = config.fetch('shardsvr')
    confsvr = config.fetch('confsvr')
    if port
      port_real = port
    elsif !port and (confsvr.eql? 'configsvr' or confsvr.eql? 'true')
      port_real = 27019
    elsif !port and (shardsvr.eql? 'shardsvr' or shardsvr.eql? 'true')
      port_real = 27018
    else
      port_real = 27017
    end

    "#{ip_real}:#{port_real}"
  end

  def self.db_ismaster
    cmd_ismaster = 'db.isMaster().ismaster'
    if mongorc_file
      cmd_ismaster = mongorc_file + cmd_ismaster
    end
    db = 'admin'
    res = mongo_cmd(db, get_conn_string, cmd_ismaster).to_s.chomp()
    res.eql?('true') ? true : false
  end

  def db_ismaster
    self.class.db_ismaster
  end

  def self.auth_enabled(config=nil)
    config ||= get_mongo_conf
    config['auth'] && config['auth'] != 'disabled'
  end

  # Mongo Command Wrapper
  def self.mongo_eval(cmd, db = 'admin', retries = 10, host = nil)
    retry_count = retries
    retry_sleep = 3
    if mongorc_file
      cmd = mongorc_file + cmd
    end

    out = nil
    retry_count.times do |n|
      begin
        if host
          out = mongo_cmd(db, host, cmd)
        else
          out = mongo_cmd(db, get_conn_string, cmd)
        end
      rescue => e
        Puppet.debug "Request failed: '#{e.message}' Retry: '#{n}'"
        sleep retry_sleep
        next
      end
      break
    end

    if !out
      raise Puppet::ExecutionFailure, "Could not evaluate MongoDB shell command: #{cmd}"
    end

    ['ObjectId','NumberLong'].each do |data_type|
      out.gsub!(/#{data_type}\(([^)]*)\)/, '\1')
    end
    out.gsub!(/^Error\:.+/, '')
    out.gsub!(/^.*warning\:.+/, '') # remove warnings if sslAllowInvalidHostnames is true
    out.gsub!(/^.*The server certificate does not match the host name.+/, '') # remove warnings if sslAllowInvalidHostnames is true mongo 3.x
    out
  end

  def mongo_eval(cmd, db = 'admin', retries = 10, host = nil)
    self.class.mongo_eval(cmd, db, retries, host)
  end

  # Called by the admin code to set the global admin user using the localhost hole when turning
  # on authentication.
  def self.noauth_admin_cmd(cmd)
    if mongorc_file
      cmd = mongorc_file + cmd
    end

    begin
      out = mongo_cmd('admin', 'localhost', cmd, true)
    rescue => e
      Puppet.debug "Unable to run admin command without auth: '#{e.message}'"
    end

    return !out
  end

  def noauth_admin_cmd(cmd)
    self.class.noauth_admin_cmd(cmd)
  end

  # check if we have valid authentication credentials. Assumes that the admin username and
  # password methods have already been called prior to this. No point calling this is auth
  # is not enabled.
  def self.has_valid_auth?
    cmd = 'db.version()'

    if mongorc_file
      cmd = mongorc_file + cmd
    end

    begin
      out = mongo_cmd('admin', 'localhost', cmd)
    rescue => e
      Puppet.debug "Auth credentials are not valid: '#{e.message}'"
    end

    return !out
  end

  def has_valid_auth?
    self.class.has_valid_auth?
  end

  # Mongo Version checker
  def self.mongo_version
    @@mongo_version ||= self.mongo_eval('db.version()')
  end

  def mongo_version
    self.class.mongo_version
  end

  def self.mongo_24?
    v = self.mongo_version
    ! v[/^2\.4\./].nil?
  end

  def mongo_24?
    self.class.mongo_24?
  end

  def self.set_admin_user(username)
    Puppet.debug "Mongo admin username set to #{username}"
    @@admin_username = username
  end

  def set_admin_user(username)
    self.class.set_admin_user(username)
  end

  def self.set_admin_password(password)
    Puppet.debug "Mongo admin password set to #{password}"
    @@admin_password = password
  end

  def set_admin_password(password)
    self.class.set_admin_password(password)
  end

end
