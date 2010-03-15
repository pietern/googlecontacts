module GoogleContacts
  class Group < Base
    CATEGORY_TERM = 'http://schemas.google.com/g/2005#group'

    def system_group?
      @xml.xpath('./gContact:systemGroup').size > 0
    end

    def inspect
      "\#<GoogleContacts::Group name=#{name.inspect} system_group=#{system_group?.inspect}>"
    end
  end
end
