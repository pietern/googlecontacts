require File.dirname(__FILE__) + '/../spec_helper'

describe GoogleContacts::Proxies::Tag do
  describe "with existing entries" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry xmlns:atom="http://www.w3.org/2005/Atom">
          <atom:title>Example</atom:title>
        </entry>
      XML
    end

    it "should initialize" do
      @proxy.should == 'Example'
    end

    it "should not be changed when initialized" do
      @proxy.changed?.should be_false
    end
  end

  describe "without existing entries" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry xmlns:atom="http://www.w3.org/2005/Atom">
        </entry>
      XML
    end

    it "should initialize the value to nil" do
      @proxy.nil?.should be_true
    end

    it "should not create the tag when initializing" do
      @parent.xml.xpath('./atom:title').should have(:no).entries
    end

    it "should not be changed when initialized" do
      @proxy.changed?.should be_false
    end

    it "should be changed when replace is called" do
      @proxy.replace("Test")
      @proxy.changed?.should be_true
    end
  end

  describe "synchronize to xml document" do
    describe "when tag doesn't exist" do
      before(:each) do
        create_proxy_from_xml <<-XML
          <entry xmlns:atom="http://www.w3.org/2005/Atom">
          </entry>
        XML
      end

      it "should create the tag" do
        @node = mock('node') { expects(:content=).with('Example') }
        @parent.expects(:insert_xml).with('atom:title').returns(@node)
        @proxy.replace("Example")
        @proxy.synchronize
      end
    end

    describe "when tag exists" do
      before(:each) do
        create_proxy_from_xml <<-XML
          <entry xmlns:atom="http://www.w3.org/2005/Atom">
            <atom:title>Example</atom:title>
          </entry>
        XML
      end

      it "should update the tag" do
        @proxy.replace("Replacement")
        @proxy.synchronize
        @parent.xml.at('./atom:title').content.should == 'Replacement'
      end
    end
  end

  def create_proxy_from_xml(str)
    @parent = stub('parent', :xml => Nokogiri::XML.parse(str).root)
    @proxy  = GoogleContacts::Proxies::Tag.new(@parent, :tag => 'atom:title')
  end
end

