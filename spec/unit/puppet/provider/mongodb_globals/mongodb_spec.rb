require 'spec_helper'
require 'tempfile'

describe Puppet::Type.type(:mongodb_globals).provider(:mongodb) do

  let(:resource) { Puppet::Type.type(:mongodb_globals).new(
    {
      :name           => 'global_test',
      :admin_username => 'admin',
      :admin_password => 'password',
      :provider       => described_class.name,
    }
  )}

  let(:provider) { resource.provider }

  let(:instance) { provider.class.instances.first }

  describe 'self.initialise' do
    it 'sets the username and password to the global class' do
      provider.expects(:set_admin_user).with('admin')
      provider.expects(:set_admin_password).with('password')
    end
  end

end
