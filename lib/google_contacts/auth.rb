module GoogleContacts
  class Auth
    GOOGLE_OAUTH = {
      :site => "https://www.google.com",
      :request_token_path => "/accounts/OAuthGetRequestToken",
      :authorize_path     => "/accounts/OAuthAuthorizeToken",
      :access_token_path  => "/accounts/OAuthGetAccessToken",
    }.freeze

    class << self
      attr_accessor :consumer_key
      attr_accessor :consumer_secret
      attr_accessor :callback_url
    end

    def self.consumer
      ::OAuth::Consumer.new(consumer_key, consumer_secret, GOOGLE_OAUTH)
    end

    def request_token(options)
      self.class.consumer.get_request_token({
        :oauth_callback => options[:callback]
      }, {
        :scope => "http://www.google.com/m8/feeds/"
      })
    end
  end
end
