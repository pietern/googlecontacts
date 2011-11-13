require 'spec_helper'

describe GoogleContacts::Wrapper do
  describe "fetching" do
    before(:each) do
      @options = { 'max-results' => 200, 'start-index' => 1 }
    end

    def params(overrides)
      @options.merge(overrides).map do |tuple|
        tuple.join('=')
      end.join('&')
    end

    def register(type, options = {})
      url = "http://www.google.com/m8/feeds/#{type}/default/full?#{params(options)}"
      FakeWeb.register_uri(:get, url, :body => yield)
    end

    it "should be able to get list of contacts" do
      register(:contacts) { asset('contacts_full') }
      result = wrapper.contacts.find(:all)
      result.should have(1).contact
      result.first.should be_a GoogleContacts::Contact
    end

    it "should be able to get list of contacts when result is paginated" do
      register(:contacts, 'start-index' =>  1) { asset('contacts_full_page1') }
      register(:contacts, 'start-index' => 26) { asset('contacts_full_page2') }
      result = wrapper.contacts.find(:all)
      result.should have(2).contacts
    end

    it "should be possible to specify the max-results parameter" do
      register(:contacts, 'max-results' => 25) { asset('contacts_full') }
      result = wrapper.contacts.find(:all, 'max-results' => 25)
      result.should have(1).contact
    end

    it "should be able to get list of groups" do
      register(:groups) { asset('groups_full') }
      result = wrapper.groups.find(:all)
      result.should have(2).groups
      result.first.should be_a GoogleContacts::Group
    end
  end

  describe "flushing" do
    it "should not allow nesting of #batch" do
      lambda {
        wrapper.batch { wrapper.batch { } }
      }.should raise_error(/not allowed/i)
    end

    it "should collect operations in a batch" do
      wrapper.should_not_receive(:post)
      document = wrapper.batch(:return_documents => true) do
        wrapper.contacts.build(:name => 'c1').save
        wrapper.contacts.build(:name => 'c2').save
      end.first

      document.xpath('.//xmlns:entry').should have(2).entries
      document.xpath('.//batch:operation').each do |operation|
        operation['type'].should == 'insert'
      end
    end

    it "should flush batches in chunks of 100" do
      wrapper.should_receive(:post).with(%r@/contacts/@, kind_of(String)).twice
      wrapper.batch do
        contact = wrapper.contacts.build(:name => 'contact')
        101.times { contact.save }
      end
    end

    it "should not flush when there are no operations to execute" do
      wrapper.should_not_receive(:post)
      wrapper.batch {}
    end

    it "should raise when mixing contacts and groups in one batch" do
      lambda {
        wrapper.batch {
          wrapper.contacts.build(:name => 'contact').save
          wrapper.groups.build(:name => 'group').save
        }
      }.should raise_error(/cannot mix/i)
    end

    it "should POST a single-operation batch to contacts when not batching" do
      wrapper.should_receive(:post).with(%r@/contacts/@, kind_of(String))
      wrapper.contacts.build(:name => 'contact').save
    end

    it "should POST a single-operation batch to groups when not batching" do
      wrapper.should_receive(:post).with(%r@/groups/@, kind_of(String))
      wrapper.groups.build(:name => 'group').save
    end
  end
end
