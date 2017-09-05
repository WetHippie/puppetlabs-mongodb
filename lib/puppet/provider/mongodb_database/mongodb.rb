require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_database).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  desc "Manages MongoDB database."

  defaultfor :kernel => 'Linux'

  def self.instances(admin_username = nil, admin_password = nil)
    require 'json'

    Puppet.debug "Listing Mongo DB instances with admin details: #{admin_username}/#{admin_password}"

    unless admin_username.nil? || admin_password.nil?
        extras = {
          :admin_pass => admin_password,
          :admin_user => admin_username,
        }

        dbs = JSON.parse mongo_eval('printjson(db.getMongo().getDBs())', extras)
    else
        dbs = JSON.parse mongo_eval('printjson(db.getMongo().getDBs())')
    end

    dbs['databases'].collect do |db|
      new(:name   => db['name'],
          :ensure => :present)
    end
  end

  # Assign prefetched dbs based on name.
  def self.prefetch(resources)
    dbs = instances
    resources.keys.each do |name|
      if provider = dbs.find { |db| db.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    puts "Create called with master #{db_ismaster}"
    extras = {
      :admin_user => @resource[:admin_username],
      :admin_pass => @resource[:admin_password]
    }

    if db_ismaster(extras)
      mongo_eval('db.dummyData.insert({"created_by_puppet": 1})', @resource[:name], extras)
    else
      Puppet.warning 'Database creation is available only from master host'
    end
  end

  def destroy
    extras = {
      :admin_user => @resource[:admin_username],
      :admin_pass => @resource[:admin_password]
    }

    if db_ismaster(extras)
      mongo_eval('db.dropDatabase()', @resource[:name], extras)
    else
      Puppet.warning 'Database removal is available only from master host'
    end
  end

  def exists?
    !(@property_hash[:ensure] == :absent or @property_hash[:ensure].nil?)
  end

end
