require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_globals).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  desc "Manages MongoDB global properties used to access the DB."

  defaultfor :kernel => 'Linux'

  mk_resource_methods

  def initialize(resource={})
    super(resource)
    @property_flush = {}

    Puppet.debug "Puppet global resource initialised with a #{@resource}. Username #{resource[:admin_username]}"

    set_admin_user(@resource[:admin_username])
    set_admin_password(@resource[:admin_password])
  end

end
