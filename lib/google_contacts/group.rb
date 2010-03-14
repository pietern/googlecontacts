module GoogleContacts
  class Group < Base
    CATEGORY_TERM = 'http://schemas.google.com/g/2005#group'

    alias_attribute :name, :title
    def initialize(*args)
      super
      register_proxy :title,  Proxies::Tag.new(self, :tag => 'xmlns:title')
    end

    def system_group?
      @xml.xpath('.//gContact:systemGroup').size > 0
    end
  end
end
