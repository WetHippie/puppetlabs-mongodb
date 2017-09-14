require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_globals).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  desc "Manages MongoDB global properties used to access the DB."

  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def self.instances
    # Always return an empty array at startup
    []
  end

  def create
    Puppet.debug "Puppet globals created. Username #{resource[:admin_username]}"

    auth_reset_needed = false

    if resource[:auth]
      set_admin_user(resource[:admin_username])
      set_admin_password(resource[:admin_password])
      auth_reset_needed = has_valid_auth?
    end

    if resource[:create_admin]
	  password_hash = Puppet::Util::MongodbMd5er.md5(@resource[:admin_username],@resource[:admin_password])

      cmd_json=<<-EOS.gsub(/^\s*/, '').gsub(/$\n/, '')
	  {
	    "createUser": "#{@resource[:username]}",
	    "pwd": "#{password_hash}",
	    "customData": {"createdBy": "Puppet Mongodb_globals['#{@resource[:name]}']"},
	    "roles": #{@resource[:roles].to_json},
	    "digestPassword": false
	  }
	  EOS

      if auth_reset_needed
        success = noauth_admin_cmd("db.runCommand(#{cmd_json})")
      else
        success = mongo_eval("db.runCommand(#{cmd_json})", 'admin')
      end
    end

    @property_hash[:ensure] = :present
  end

  def exists?
    !(@property_hash[:ensure] == :absent or @property_hash[:ensure].nil?)
  end

end
