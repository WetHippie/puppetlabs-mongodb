Puppet::Type.newtype(:mongodb_globals) do
  @doc = "Manage MongoDB parent authentication global information. This is an internal class
          that is used to pass the authentication flag, and option admin username and password
          down to the lower level providers. This should not be used by an end user."

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar=>true) do
    desc "Any name. Ignored by this global class."
  end

  newparam(:admin_username) do
    desc "Admin's user name needed to create the user. Only needed if auth is enabled on the server.
     This should be identical to the mongodb::server::admin_user property"

    newvalues(/^[\w-]+$/)
  end

  newparam(:admin_password) do
    desc "Admin's user cleartext password needed to create the user. Only needed if auth is enabled on
     the server. This should be identical to the mongodb::server::admin_user property"

    newvalues(/^[\w-]+$/)
  end

  newparam(:auth, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc "Flag describing whether authentication is enabled on MongoDB. Defaults to no authentication.
          If enabled, you need to also provide the username and password for the admin user."
  end

  autorequire(:package) do
    'mongodb_client'
  end

  autorequire(:service) do
    'mongodb'
  end

  validate do
    if self[:auth] and self[:admin_username].nil? and self[:admin_password].nil?
      if self[:admin_username].nil?
        if self[:admin_password].nil?
          err("Auth is enabled and both admin username and password are missing")
        else
          err("Auth is enabled and admin username is missing")
        end
      else
        err("Auth is enabled and admin password is missing")
      end
    end
  end

end
