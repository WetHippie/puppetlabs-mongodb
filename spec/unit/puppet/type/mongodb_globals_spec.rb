require 'puppet'
require 'puppet/type/mongodb_database'
describe Puppet::Type.type(:mongodb_globals) do

  before :each do
    @data = Puppet::Type.type(:mongodb_globals).new(:name => 'test')
  end

  it 'should accept a database name' do
    expect(@data[:name]).to eq('test')
  end

  it 'should accept a auth parameter' do
    @data[:auth] = true
    expect(@data[:auth]).to eq(true)
  end

  it 'should accept a username parameter' do
    @data[:admin_username] = 'admin123'
    expect(@data[:admin_username]).to eq('admin123')
  end

  it 'should accept a password parameter' do
    @data[:admin_password] = 'pass1234'
    expect(@data[:admin_password]).to eq('pass1234')
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:mongodb_globals).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

end
