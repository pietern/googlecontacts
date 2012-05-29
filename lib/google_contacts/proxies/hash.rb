module GoogleContacts
  module Proxies
    class Hash < ActiveSupport::BasicObject
      def initialize(parent, options)
        @parent = parent
        @tag    = options[:tag]
        @key    = options[:key]
        @value  = options[:value]

        reinitialize
      end

      def reinitialize
        @current = ::HashWithIndifferentAccess.new
        @parent.xml.xpath("./#{@tag}").map do |entry|
          @current[entry[@key]] = entry[@value]
        end

        # create a deep copy
        @new = ::HashWithIndifferentAccess.new
        @current.each do |k,v| 
          @new[k.dup] = v.dup unless v.nil?
        end
      end

      def changed?
        @current != @new
      end

      def synchronize
        @parent.remove_xml("./#{@tag}")
        @new.each_pair do |key, value|
          @parent.insert_xml(@tag, @key => key, @value => value)
        end
      end

      private
      def method_missing(sym, *args, &blk)
        @new.send(sym, *args, &blk)
      end
    end # class Hash
  end # module Proxies
end # module GoogleContacts
