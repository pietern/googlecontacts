require "rspec"
require "fakeweb"
require "google_contacts"

module Helpers
  def consumer
    ::OAuth::AccessToken.new(GoogleContacts::Auth.consumer, 'key', 'secret')
  end

  def wrapper
    @wrapper ||= GoogleContacts::Wrapper.new(consumer)
  end

  def asset(file)
    File.read File.join(File.dirname(__FILE__), "assets", "#{file}.xml")
  end

  def parsed_asset(file)
    Nokogiri::XML.parse asset(file)
  end
end

FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.include Helpers
end
