require File.dirname(__FILE__) + '/../spec_helper'

describe Proxies::Hash do
  describe "with existing entries" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry>
          <prop name="foo" value="bar" />
        </entry>
      XML
    end

    it "should initialize on creation" do
      @proxy[:foo].should == 'bar'
      @proxy.should have(1).entry
    end
  end

  describe "without existing entries" do
    before(:each) do
      create_proxy_from_xml "<entry></entry>"
    end

    it "should allow setting a value" do
      @proxy[:foo] = 'bar'
      @proxy.should have(1).entry
      @proxy[:foo].should == 'bar'
    end

    it "should allow clearing" do
      @proxy[:foo] = 'bar'
      @proxy.clear
      @proxy.should have(:no).entries
    end
  end

  describe "knows when it is changed" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry>
          <prop name="foo" value="foo" />
        </entry>
      XML
    end

    it "should work when a new value was set" do
      lambda {
        @proxy[:foo] = 'quux'
      }.should change(@proxy, :changed?).from(false).to(true)
    end

    it "should not be changed when the new value equals the old one" do
      lambda {
        @proxy[:foo] = 'foo'
      }.should_not change(@proxy, :changed?).from(false)
    end
  end

  describe "synchronize to xml document" do
    before(:each) do
      create_proxy_from_xml "<entry></entry>"
    end

    it "should update the group entries" do
      @proxy[:foo] = 'quux'
      @proxy[:baz] = 'bar'
      @parent.expects(:remove_xml).with('./prop')
      @parent.expects(:insert_xml).with('prop', { 'name' => 'foo', 'value' => 'quux' })
      @parent.expects(:insert_xml).with('prop', { 'name' => 'baz', 'value' => 'bar'  })
      @proxy.synchronize
    end
  end

  def create_proxy_from_xml(str)
    @parent = stub('parent', :xml => Nokogiri::XML.parse(str).root)
    @proxy  = Proxies::Hash.new(@parent, :tag => 'prop', :key => 'name', :value => 'value')
  end
end
