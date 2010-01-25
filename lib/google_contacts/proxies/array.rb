module GoogleContacts
  module Proxies
    class Array < BlankSlate
      def initialize(parent, options)
        @parent = parent
        @tag    = options[:tag]
        @attr   = options[:attr]

        reinitialize
      end

      def reinitialize
        @current = @parent.xml.xpath("./#{@tag}").map do |entry|
          entry[@attr]
        end.compact.uniq.sort

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

      def push(item)
        item = item.href if item.respond_to?(:href)
        method_missing(:push, item)
      end
      alias :<< :push

      private
      def method_missing(sym, *args, &blk)
        ret = @new.send(sym, *args, &blk)
        @new = @new.compact.uniq.sort
        ret
      end
    end # class Array
  end # module Proxies
end # module GoogleContacts
