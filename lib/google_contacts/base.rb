module GoogleContacts
  class Base
    NAMESPACES = {
      'atom'        => 'http://www.w3.org/2005/Atom',
      'openSearch'  => 'http://a9.com/-/spec/opensearch/1.1/',
      'gContact'    => 'http://schemas.google.com/contact/2008',
      'batch'       => 'http://schemas.google.com/gdata/batch',
      'gd'          => 'http://schemas.google.com/g/2005',
    }.freeze

    attr_reader :xml
    def initialize(wrapper, xml = nil)
      raise "Cannot create instance of Base" if self.class.name.split(/::/).last == 'Base'
      @wrapper = wrapper

      # If a root node is given, create a new XML document based on
      # a deep copy. Otherwise, initialize a new XML document.
      @xml = if xml.present?
        self.class.new_xml_document(xml).root
      else
        self.class.initialize_xml_document.root
      end

      @proxies = HashWithIndifferentAccess.new
    end

    def attributes=(attrs)
      attrs.each_pair do |key, value|
        send("#{key}=", value)
      end
    end

    def insert_xml(tag, attributes = {}, &blk)
      self.class.insert_xml(@xml, tag, attributes, &blk)
    end

    def remove_xml(tag)
      @xml.xpath(tag).remove
    end

    def self.feed_for_batch
      new_xml_document('feed').root
    end

    # Create new XML::Document that can be used in a
    # Google Contacts batch operation.
    def entry_for_batch(operation)
      doc = self.class.new_xml_document(xml)
      doc.root.xpath('./xmlns:link'   ).remove
      doc.root.xpath('./xmlns:updated').remove

      if operation == :update || operation == :delete
        doc.root.at('./xmlns:id').content = url(:edit)
      end

      self.class.insert_xml(doc.root, 'batch:id')
      self.class.insert_xml(doc.root, 'batch:operation', :type => operation)

      doc.root
    end

    def new?
      xml.at_xpath('./xmlns:id').nil?
    end

    def id
      xml.at_xpath('./xmlns:id').text.strip unless new?
    end

    def updated_at
      Time.parse xml.at_xpath('./xmlns:updated').text.strip unless new?
    end

    def url(rel)
      rel = 'http://schemas.google.com/contacts/2008/rel#photo' if rel == :photo
      xml.at_xpath(%{xmlns:link[@rel="#{rel}"]})[:href]
    end

    def changed?
      @proxies.values.any?(&:changed?)
    end

    def save
      return unless changed?
      synchronize_proxies
      @wrapper.append_operation(self, new? ? :insert : :update)
    end

    def delete
      return if new?
      @wrapper.append_operation(self, :delete)
    end

    protected
    def register_proxy(name, proxy)
      @proxies[name.to_sym] = proxy
    end

    def synchronize_proxies
      @proxies.values.map(&:synchronize)
    end

    # Try to proxy missing method to one of the proxies
    def method_missing(sym, *args, &blk)
      if sym.to_s =~ /^(\w+)(=)?$/ && @proxies[$1]
        if $2
          @proxies[$1].replace(args.first)
        else
          @proxies[$1]
        end
      else
        super
      end
    end

    def self.namespace(node, prefix)
      node.namespace_definitions.find do |ns|
        ns.prefix == prefix
      end
    end

    def self.insert_xml(parent, tag, attributes = {}, &blk)
      # Construct new node with the right namespace
      matches = tag.match /^((\w+):)?(\w+)$/
      ns      = matches[2] == 'xmlns' ? 'atom' : (matches[2] || 'atom')
      tag     = matches[3]
      node = Nokogiri::XML::Node.new(tag, parent)
      node.namespace = namespace(parent, ns) || raise("Unknown namespace: #{ns}")

      attributes.each_pair do |k,v|
        node[k.to_s] = v.to_s
      end

      parent << node
      yield node if block_given?
      node
    end

    def self.new_xml_document(root)
      doc = Nokogiri::XML::Document.new
      if root.is_a?(Nokogiri::XML::Element)
        doc.root = root.dup(1)
      else
        doc.root = Nokogiri::XML::Node.new(root, doc)
      end
      decorate_document_with_namespaces(doc)
      doc
    end

    def self.initialize_xml_document
      doc = new_xml_document('entry')
      insert_xml(doc.root, 'atom:category', {
        :scheme => 'http://schemas.google.com/g/2005#kind',
        :term   => const_get(:CATEGORY_TERM)
      })
      doc
    end

    def self.decorate_document_with_namespaces(doc)
      doc.root.default_namespace = NAMESPACES['atom']
      NAMESPACES.each_pair do |prefix, href|
        doc.root.add_namespace(prefix, href)
      end
      doc
    end
  end
end
