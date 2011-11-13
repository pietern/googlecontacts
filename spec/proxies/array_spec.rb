require 'spec_helper'

describe GoogleContacts::Proxies::Array do
  describe "with existing entries" do
    before(:each) do
      create_proxy_from_xml %{<entry><group href="http://some.group" /></entry>}
    end

    it "should initialize on creation" do
      @proxy.size.should == 1
      @proxy[0].should == 'http://some.group'
    end
  end

  describe "without existing entries" do
    before(:each) do
      create_proxy_from_xml "<entry></entry>"
    end

    it "should allow pushing a plain value" do
      @proxy << 'http://foo'
      @proxy.should have(1).group
      @proxy[0].should == 'http://foo'
    end

    it "should allow pushing an object that responds to href" do
      @proxy << mock('Group', :href => 'http://foo')
      @proxy.should have(1).group
      @proxy[0].should == 'http://foo'
    end

    it "should filter duplicates" do
      @proxy << 'http://foo'
      @proxy << 'http://foo'
      @proxy.should have(1).group
    end

    it "should filter nils" do
      @proxy << nil
      @proxy.should have(:no).groups
    end

    it "should allow clearing" do
      @proxy << 'http://foo'
      @proxy.clear
      @proxy.should have(:no).groups
    end
  end

  describe "knows when it is changed" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry>
          <group href="http://some.group" />
          <group href="http://another.group" />
        </entry>
      XML
    end

    it "should work after pushing a new entry" do
      lambda {
        @proxy << 'http://foo'
      }.should change(@proxy, :changed?).from(false).to(true)
    end

    it "should not be changed when a duplicate is added" do
      lambda {
        @proxy << 'http://some.group'
      }.should_not change(@proxy, :changed?).from(false)
    end

    it "should not be changed when nils are added" do
      lambda {
        @proxy.concat [nil, nil]
      }.should_not change(@proxy, :changed?).from(false)
    end

    it "should not be influenced by order" do
      lambda {
        @proxy.replace ['http://another.group', 'http://some.group']
      }.should_not change(@proxy, :changed?).from(false)
    end
  end

  describe "synchronize to xml document" do
    before(:each) do
      create_proxy_from_xml "<entry></entry>"
    end

    it "should update the group entries" do
      @proxy << 'http://another.group'
      @proxy << 'http://some.group'
      @parent.expects(:remove_xml).with('./group')
      @parent.expects(:insert_xml).with('group', { 'href' => 'http://another.group' })
      @parent.expects(:insert_xml).with('group', { 'href' => 'http://some.group'    })
      @proxy.synchronize
    end
  end

  def create_proxy_from_xml(str)
    @parent = mock('parent', :xml => Nokogiri::XML.parse(str).root)
    @proxy  = GoogleContacts::Proxies::Array.new(@parent, :tag => 'group', :attr => 'href')
  end
end

