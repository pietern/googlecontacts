require "google_contacts/base"

module GoogleContacts
  class Contact < Base
    CATEGORY_TERM = "http://schemas.google.com/contact/2008#contact"

    def initialize(*args)
      super
      register_proxy :emails, Proxies::Emails.new(self)
      register_proxy :groups, Proxies::Array.new(self,
        :tag   => "gContact:groupMembershipInfo",
        :attr  => "href")
    end

    # Alias "name" to "title"
    def name
      method_missing(:title)
    end

    def name=(v)
      method_missing(:title=, v)
    end

    def email
      primary = emails.primary
      primary && primary.address
    end

    def email=(address)
      emails[address].primary!
    end

    def inspect
      "\#<GoogleContacts::Contact name=#{name.inspect} email=#{email.inspect}>"
    end
  end # class Contact
end # module GoogleContacts
