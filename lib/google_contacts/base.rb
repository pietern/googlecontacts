module GoogleContacts
  class Base
    NAMESPACES = {
      'atom'        => 'http://www.w3.org/2005/Atom',
      'openSearch'  => 'http://a9.com/-/spec/opensearch/1.1/',
      'gContact'    => 'http://schemas.google.com/contact/2008',
      'batch'       => 'http://schemas.google.com/gdata/batch',
      'gd'          => 'http://schemas.google.com/g/2005',
    }.freeze

    # DEFAULT_NAMESPACE = 'http://www.w3.org/2005/Atom'.freeze

    attr_reader :xml
    def initialize(wrapper, xml = nil)
      raise "Cannot create instance of Base" if self.class.name.split(/::/).last == 'Base'
      @wrapper = wrapper
      @xml     = self.class.decorate_with_namespaces(xml || initialize_xml_document)
      @proxies = HashWithIndifferentAccess.new
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

    def remove_xml(tag)
      @xml.xpath(tag).remove
    end

    def insert_xml(tag, attributes = {}, &blk)
      self.class.insert_xml(@xml, tag, attributes, &blk)
    end

    def self.feed_for_batch
      xml = Nokogiri::XML::Document.new
      xml.root = decorate_with_namespaces(Nokogiri::XML::Node.new('feed', xml))
      xml.root
    end

    def xml_copy
      doc = Nokogiri::XML::Document.new
      doc.root = self.class.decorate_with_namespaces(xml.dup)
      doc.root
    end

    # Create new XML::Document that can be used in a
    # Google Contacts batch operation.
    def entry_for_batch(operation)
      doc = Nokogiri::XML::Document.new
      doc.root = self.class.decorate_with_namespaces(xml.dup) # This automatically dups xml
      doc.root.xpath('./xmlns:link'   ).remove
      doc.root.xpath('./xmlns:updated').remove

      if operation == :update || operation == :destroy
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
      new? || @proxies.values.any?(&:changed?)
    end

    def save
      return unless changed?
      synchronize_proxies
      @wrapper.save(self)
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
      if sym.to_s =~ /^(\w+)(=)?$/ && @proxies[$1.to_sym]
        if $2
          @proxies[$1].replace(args.first)
        else
          @proxies[$1]
        end
      else
        super
      end
    end

    def initialize_xml_document
      xml = Nokogiri::XML::Document.new
      xml.root = Nokogiri::XML::Node.new('entry', xml)

      category = Nokogiri::XML::Node.new('category', xml)
      category['scheme'] = 'http://schemas.google.com/g/2005#kind'
      category['term'  ] = self.class.const_get(:CATEGORY_TERM)
      xml.root << category

      xml.root
    end

    def self.decorate_with_namespaces(node)
      node.default_namespace = NAMESPACES['atom']
      NAMESPACES.each_pair do |prefix, href|
        node.add_namespace(prefix, href)
      end
      node
    end
  end
end
