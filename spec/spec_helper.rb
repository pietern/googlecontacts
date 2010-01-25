$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'spec'
require 'spec/autorun'
require 'pp'

require 'fakeweb'
FakeWeb.allow_net_connect = false

require 'google_contacts'
include GoogleContacts

module Helpers
  def consumer
    ::OAuth::AccessToken.new(Auth.consumer, 'key', 'secret')
  end

  def wrapper
    @wrapper ||= Wrapper.new(consumer)
  end

  def asset(file)
    File.read File.join(File.dirname(__FILE__), "assets", "#{file}.xml")
  end

  def parsed_asset(file)
    Nokogiri::XML.parse asset(file)
  end
end

Spec::Runner.configure do |config|
  config.include(Helpers)
  config.mock_with :mocha
end
