require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_globals).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  desc "Manages MongoDB global properties used to access the DB."

  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def initialize(resource={})
    super(resource)
    @property_flush = {}

    Puppet.debug "Puppet global resource initialised"
  end

  def admin_username=(value)
    set_admin_user(value)
    @property_flush[:admin_username] = value

    Puppet.debug "Set the admin username to #{value}"
  end

  def admin_password=(value)
    set_admin_password(value)
    @property_flush[:admin_password] = value

    Puppet.debug "Set the admin password to #{value}"
  end

end
