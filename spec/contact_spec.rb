require File.dirname(__FILE__) + '/spec_helper'

describe Contact do
  describe "when loaded" do
    before(:each) do
      entries = parsed_asset('contacts_full').search('feed > entry')
      @contacts = entries.map { |entry| Contact.new(wrapper, entry) }
      @contact  = @contacts.first
    end

    it "should know its id" do
      @contact.id.should == 'http://www.google.com/m8/feeds/contacts/liz%40gmail.com/base/c9012de'
    end

    it "should know when it was updated" do
      @contact.updated_at.should == Time.utc(2008, 12, 10, 04, 45, 03, 331000)
    end

    it "should initialize with groups from xml" do
      @contact.groups.should have(1).group
      @contact.groups[0].should == 'http://www.google.com/m8/feeds/groups/liz%40gmail.com/base/270f'
    end

    it "should initialize extended properties" do
      @contact[:pet].should == 'hamster'
    end

    it "should not be changed? initially" do
      @contact.changed?.should be_false
    end

    describe "urls" do
      it "should know its self url" do
        @contact.url(:self).should == 'http://www.google.com/m8/feeds/contacts/liz%40gmail.com/full/c9012de'
      end

      it "should know its edit url" do
        @contact.url(:edit).should == 'http://www.google.com/m8/feeds/contacts/liz%40gmail.com/full/c9012de'
      end

      it "should know its photo url" do
        @contact.url(:photo).should == 'http://www.google.com/m8/feeds/photos/media/liz%40gmail.com/c9012de'
      end
    end
  end

  describe "initializing" do
    before(:each) do
      @contact = Contact.new(wrapper)
      @root = @contact.xml.document.root
    end

    it "should create a new xml root node" do
      @root.name.should == 'entry'
      @root.namespace.href.should == 'http://www.w3.org/2005/Atom'
    end

    it "should set the right category term" do
      @root.at_xpath('./category')['term'].should == 'http://schemas.google.com/contact/2008#contact'
    end

    it "should not have an id" do
      @contact.id.should be_nil
    end

    it "should not have an updated entry" do
      @contact.updated_at.should be_nil
    end

    it "should always be changed" do
      @contact.changed?.should be_true
    end

    it "should be possible to set the default email address" do
      @contact.email = 'foo@bar.com'
      @contact.emails['foo@bar.com'].should be_primary
      @contact.emails.size.should == 1
    end
  end

  def xpath(path)
    @contact.xml.xpath(path)
  end
end
