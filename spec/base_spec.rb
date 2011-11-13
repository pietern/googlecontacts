require 'spec_helper'

class GoogleContacts::BaseTester < GoogleContacts::Base
  CATEGORY_TERM = "i'm not used here"
end

describe GoogleContacts::Base do
  it "should not be possible to create" do
    lambda {
      GoogleContacts::Base.new(wrapper, 'some xml')
    }.should raise_error(/cannot create instance/i)
  end

  describe "with an XML document" do
    before(:each) do
      @t = GoogleContacts::BaseTester.new(wrapper)
    end

    it "should default namespace to document default" do
      node = @t.insert_xml 'tag'
      node.namespace.href.should == 'http://www.w3.org/2005/Atom'
      @t.xml.xpath('atom:tag').should have(1).node
    end

    it "should set namespace when specified in tag" do
      node = @t.insert_xml 'gd:extendedProperty'
      node.namespace.href.should == 'http://schemas.google.com/g/2005'
      @t.xml.xpath('gd:extendedProperty').should have(1).node

      node = @t.insert_xml 'gContact:birthday'
      node.namespace.href.should == 'http://schemas.google.com/contact/2008'
      @t.xml.xpath('gContact:birthday').should have(1).node
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
      @t.xml.xpath('./gd:extendedProperty').should have(1).node

      @t.remove_xml 'gd:extendedProperty'
      @t.xml.xpath('./gd:extendedProperty').should have(:no).nodes
    end
  end

  describe "basic crud" do
    before(:each) do
      @wrapper = wrapper
      @entry   = GoogleContacts::BaseTester.new(@wrapper)
    end

    # It is not sane to try and save a default entry
    it "should not save when an entry is new but has no changed fields" do
      @entry.stub(:new? => true, :changed? => false)
      @wrapper.should_not_receive(:append_operation)
      @entry.save
    end

    it "should save when an entry is new and has changed fields" do
      @entry.stub(:new? => true, :changed? => true)
      @wrapper.should_receive(:append_operation).with(@entry, :insert)
      @entry.save
    end

    it "should save when an entry has changed fields" do
      @entry.stub(:new? => false, :changed? => true)
      @wrapper.should_receive(:append_operation).with(@entry, :update)
      @entry.save
    end

    it "should not delete when an entry is new" do
      @entry.stub(:new? => true)
      @wrapper.should_not_receive(:append_operation)
      @entry.delete
    end

    it "should delete when an entry is not new" do
      @entry.stub(:new? => false)
      @wrapper.should_receive(:append_operation).with(@entry, :delete)
      @entry.delete
    end
  end

  describe "prepare for batch operation" do
    before(:all) do
      @t = GoogleContacts::BaseTester.new(wrapper, parsed_asset('contacts_full').at('feed > entry'))
      @batch = @t.entry_for_batch(:update)
    end

    it "should not share the same document" do
      @batch.document.should_not == @t.xml.document
    end

    it "should create a duplicate node without link tags" do
      @batch.xpath('./atom:link').should be_empty
    end

    it "should not touch the category tag" do
      @batch.xpath('./atom:category').should_not be_nil
    end

    it "should remove the updated tag (not useful when updating)" do
      @batch.xpath('./atom:updated').should be_empty
    end

    it "should be possible to combine feed_for_batch and entry_for_batch" do
      feed = GoogleContacts::BaseTester.feed_for_batch
      feed << @t.entry_for_batch(:update)
    end

    it "should corretly set the batch:operation tag" do
      %(insert update delete).each do |op|
        batch = @t.entry_for_batch(op.to_sym)
        batch.at('./batch:operation')['type'].should == op
      end
    end
  end
end
