module GoogleContacts
  class Contact < Base
    CATEGORY_TERM = 'http://schemas.google.com/contact/2008#contact'

    alias_attribute :name, :title
    def initialize(*args)
      super
      register_proxy :emails, Proxies::Emails.new(self)
      register_proxy :groups, Proxies::Array.new(self,
        :tag   => 'gContact:groupMembershipInfo',
        :attr  => 'href')
    end

    def email
      emails.primary.try(:address)
    end

    def email=(address)
      emails[address].primary!
    end

    def inspect
      "\#<GoogleContacts::Contact name=#{name.inspect} email=#{email.inspect}>"
    end
  end # class Contact
end # module GoogleContacts
