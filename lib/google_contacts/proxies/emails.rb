module GoogleContacts
  module Proxies
    class Emails < ActiveSupport::BasicObject
      def initialize(parent)
        @parent = parent
        reinitialize
      end

      def reinitialize
        @current = ::Hash[*@parent.xml.xpath("./gd:email").map do |entry|
          email = Email.new(self, entry.attributes)
          [email.address, email]
        end.flatten]

        # create a deep copy
        @new = ::Hash[*@current.map do |k,v|
          [k.dup, v.dup]
        end.flatten]
      end

      def changed?
        @current != @new
      end

      def primary
        @new.values.find { |email| email.primary? } || @new.values.first
      end

      def primary!(address)
        @new.each do |key, email|
          if key == address
            email.primary = true
          else
            email.delete(:primary)
          end
        end
      end

      def <<(address)
        raise "Duplicate address" if @new[address]
        add(address)
      end

      def [](address)
        @new[address] || add(address)
      end

      def synchronize
        @parent.remove_xml("./gd:email")
        @new.each_pair do |address, email|
          @parent.insert_xml("gd:email", email)
        end
      end

      def inspect
        @new.values.inspect
      end

      private
      def add(address)
        set_primary = @new.empty?
        @new[address] = Email.new(self, { :address => address })
        @new[address].primary = true if set_primary
        @new[address]
      end

      def method_missing(sym, *args, &blk)
        if [:size, :delete].include?(sym)
          @new.send(sym, *args, &blk)
        else
          super
        end
      end

      class Email < ::HashWithIndifferentAccess
        DEFAULTS = {
          :rel => "http://schemas.google.com/g/2005#home"
        }.freeze

        alias_attribute :name, :displayName

        def initialize(parent, attributes = {})
          super(DEFAULTS)
          @parent = parent

          attributes.each do |key, value|
            send("#{key}=", value)
          end
        end

        def primary!
          @parent.primary! self[:address]
        end

        def rel=(arg)
          delete(:label)
          method_missing("rel=", arg)
        end

        def label=(arg)
          delete(:rel)
          method_missing("label=", arg)
        end

        def []=(key, value)
          if "#{key}" == "address" && self[key]
            raise "Cannot modify email address"
          end
          super(key, value.to_s)
        end

        def dup
          self.class.new(@parent, self)
        end

        def method_missing(sym, *args, &blk)
          if sym.to_s =~ /^(\w+)(=|\?)?$/
            case $2
            when "="
              send(:[]=, $1, *args)
            when "?"
              send(:[], $1) == "true"
            else
              send(:[], $1)
            end
          else
            super
          end
        end
      end # class Email
    end # class Emails
  end # module Proxies
end # module GoogleContacts
