require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_globals).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  def admin_username=(value)
    set_admin_user(value)
  end

  def admin_password=(value)
    set_admin_password(value)
  end

end
