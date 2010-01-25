require File.dirname(__FILE__) + '/spec_helper'

describe Wrapper do
  describe "fetching" do
    it "should be able to get list of contacts" do
      FakeWeb.register_uri(:get,
        'http://www.google.com/m8/feeds/contacts/default/full',
        :body => asset('contacts_full')
      )

      result = wrapper.contacts.find(:all)
      result.should have(1).contact
      result.first.should be_a Contact
    end

    it "should be able to get list of groups" do
      FakeWeb.register_uri(:get,
        'http://www.google.com/m8/feeds/groups/default/full',
        :body => asset('groups_full')
      )

      result = wrapper.groups.find(:all)
      result.should have(2).groups
      result.first.should be_a Group
    end
  end

  describe "flushing" do
    it "should not allow nesting of #batch" do
      lambda {
        wrapper.batch { wrapper.batch { } }
      }.should raise_error(/not allowed/i)
    end

    it "should collect operations in a batch" do
      wrapper.expects(:post).never
      document = wrapper.batch(:return_documents => true) do
        wrapper.contacts.build.save
        wrapper.contacts.build.save
      end.first

      document.xpath('.//xmlns:entry').should have(2).entries
      document.xpath('.//batch:operation').each do |operation|
        operation['type'].should == 'insert'
      end
    end

    it "should flush batches in chunks of 100" do
      wrapper.expects(:post).with(regexp_matches(%r!/contacts/!), is_a(String)).twice
      wrapper.batch do
        contact = wrapper.contacts.build
        101.times { contact.save }
      end
    end

    it "should raise when mixing contacts and groups in one batch" do
      lambda {
        wrapper.batch {
          wrapper.contacts.build.save
          wrapper.groups.build.save
        }
      }.should raise_error(/cannot mix/i)
    end

    it "should POST a single-operation batch to contacts when not batching" do
      wrapper.expects(:post).with(regexp_matches(%r!/contacts/!), is_a(String))
      wrapper.contacts.build.save
    end

    it "should POST a single-operation batch to groups when not batching" do
      wrapper.expects(:post).with(regexp_matches(%r!/groups/!), is_a(String))
      wrapper.groups.build.save
    end
  end
end
