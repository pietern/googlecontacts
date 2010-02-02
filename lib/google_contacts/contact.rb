module GoogleContacts
  class Contact < Base
    CATEGORY_TERM = 'http://schemas.google.com/contact/2008#contact'

    alias_attribute :name, :title
    def initialize(*args)
      super

      register_proxy :title,  Proxies::Tag.new(self, :tag => 'xmlns:title')
      register_proxy :emails, Proxies::Emails.new(self)
      register_proxy :groups, Proxies::Array.new(self,
        :tag   => 'gContact:groupMembershipInfo',
        :attr  => 'href')
      register_proxy :properties, Proxies::Hash.new(self,
        :tag   => 'gd:extendedProperty',
        :key   => 'name',
        :value => 'value')
    end

    def [](prop)
      properties[prop]
    end

    def []=(prop, value)
      properties[prop] = value
    end

    def email
      emails.primary.try(:address)
    end

    def email=(address)
      emails[address].primary!
    end

  end # class Contact
end # module GoogleContacts
