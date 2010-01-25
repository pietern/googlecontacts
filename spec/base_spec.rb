require File.dirname(__FILE__) + '/spec_helper'

class BaseTester < Base
  CATEGORY_TERM = "i'm not used here"
end

describe Base do
  it "should not be possible to create" do
    lambda {
      Base.new(wrapper, 'some xml')
    }.should raise_error(/cannot create instance/i)
  end

  describe "with an XML document" do
    before(:each) do
      @t = BaseTester.new(wrapper)
    end

    it "should default namespace to document default" do
      node = @t.insert_xml 'tag'
      node.namespace.href.should == 'http://www.w3.org/2005/Atom'
      @t.xpath('xmlns:tag').should have(1).node
    end

    it "should set namespace when specified in tag" do
      node = @t.insert_xml 'gd:extendedProperty'
      node.namespace.href.should == 'http://schemas.google.com/g/2005'
      @t.xpath('gd:extendedProperty').should have(1).node

      node = @t.insert_xml 'gContact:birthday'
      node.namespace.href.should == 'http://schemas.google.com/contact/2008'
      @t.xpath('gContact:birthday').should have(1).node
    end

    it "should raise on unknown namespace" do
      lambda {
        @t.insert_xml 'unknown:foo'
      }.should raise_error(/unknown namespace/i)
    end

    it "should also set attributes if given" do
      node = @t.insert_xml 'tag', :foo => 'bar'
      node['foo'].should == 'bar'
    end

    it "should allow removing xml" do
      @t.insert_xml 'gd:extendedProperty'
      @t.xpath('./gd:extendedProperty').should have(1).node

      @t.remove_xml 'gd:extendedProperty'
      @t.xpath('./gd:extendedProperty').should have(:no).nodes
    end
  end

  describe "prepare for batch operation" do
    before(:all) do
      @t = BaseTester.new(wrapper, parsed_asset('contacts_full').at('feed > entry'))
      @batch = @t.entry_for_batch(:update)
    end

    it "should not share the same document" do
      @batch.document.should_not == @t.xml.document
    end

    it "should create a duplicate node without link tags" do
      @batch.xpath('./xmlns:link').should be_empty
    end

    it "should remove the updated tag (not useful when updating)" do
      @batch.xpath('./xmlns:updated').should be_empty
    end

    it "should be possible to combine feed_for_batch and entry_for_batch" do
      feed = BaseTester.feed_for_batch
      feed << @t.entry_for_batch(:update)
    end
  end
end
