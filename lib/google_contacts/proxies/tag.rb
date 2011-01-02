module GoogleContacts
  module Proxies
    class Tag < ActiveSupport::BasicObject
      # Proxy #nil? to the value of the tag
      undef_method :nil? if instance_methods.include?("nil?")

      def initialize(parent, options)
        @parent = parent
        @tag    = options[:tag]

        reinitialize
      end

      def reinitialize
        @current = node.try(:content)
        @new     = @current ? @current.dup : nil
      end

      def changed?
        @current != @new
      end

      def replace(content)
        @new = content.to_s
      end

      def synchronize
        (node || insert_node).content = @new
      end

      private
      def node
        @parent.xml.at_xpath("./#{@tag}")
      end

      def insert_node
        @parent.insert_xml(@tag)
      end

      def method_missing(sym, *args, &blk)
        if @new.respond_to?(sym)
          @new.send(sym, *args, &blk)
        else
          super
        end
      end
    end # class Tag
  end # module Proxies
end # module GoogleContacts
