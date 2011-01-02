module GoogleContacts
  module Proxies
    class Array < ActiveSupport::BasicObject
      def initialize(parent, options)
        @parent = parent
        @tag    = options[:tag]
        @attr   = options[:attr]

        reinitialize
      end

      def reinitialize
        @current = sanitize(@parent.xml.xpath("./#{@tag}").map do |entry|
          entry[@attr]
        end)

        # create a deep copy
        @new = @current.map { |item| item.dup }
      end

      def changed?
        @current != @new
      end

      def synchronize
        @parent.remove_xml("./#{@tag}")
        @new.each do |value|
          @parent.insert_xml(@tag, { @attr => value })
        end
      end

      def replace(content)
        @new = sanitize([content].flatten)
      end

      private
      # Extract href from arguments if the operation changes
      # the contents of the array.
      def method_missing(sym, *args, &blk)
        if [:<<, :push, :+, :-, :concat].include?(sym)
          args = href_from_items(*args)
        end

        result = @new.send(sym, *args, &blk)
        @new = sanitize(@new)
        result
      end

      def sanitize(array)
        array.compact.uniq.sort
      end

      def href_from_items(*items)
        items.map do |item|
          if item.is_a?(::Array)
            href_from_items(*item)
          else
            item.respond_to?(:href) ? item.href : item
          end
        end
      end
    end # class Array
  end # module Proxies
end # module GoogleContacts
