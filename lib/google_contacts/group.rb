module GoogleContacts
  class Group < Base
    CATEGORY_TERM = 'http://schemas.google.com/g/2005#group'

    def system_group?
      @xml.xpath('.//gContact:systemGroup').size > 0
    end
  end
end
