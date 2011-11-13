require 'spec_helper'

describe GoogleContacts::Contact do
  describe "when loaded" do
    before(:each) do
      entries = parsed_asset('contacts_full').search('feed > entry')
      @contacts = entries.map { |entry| GoogleContacts::Contact.new(wrapper, entry) }
      @contact  = @contacts.first
    end

    it "should know its href" do
      @contact.href.should == 'http://www.google.com/m8/feeds/contacts/liz%40gmail.com/base/c9012de'
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

    it "should initialize the title tag" do
      @contact.title.should == 'Fitzwilliam Darcy'
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

    describe "updating" do
      it "should update the title-tag" do
        @contact.xml.at('./atom:title').content.should == 'Fitzwilliam Darcy'
        @contact.title = 'foo'
        @contact.title.synchronize
        @contact.xml.at('./atom:title').content.should == 'foo'
      end
    end
  end

  describe "from scratch" do
    before(:each) do
      @contact = GoogleContacts::Contact.new(wrapper)
      @root = @contact.xml.document.root
    end

    it "should create a new xml root node" do
      @root.name.should == 'entry'
      @root.namespace.href.should == 'http://www.w3.org/2005/Atom'
    end

    it "should set the right category term" do
      @root.at_xpath('./atom:category')['term'].should == 'http://schemas.google.com/contact/2008#contact'
    end

    it "should not have an href" do
      @contact.href.should be_nil
    end

    it "should not have an updated entry" do
      @contact.updated_at.should be_nil
    end

    it "should be new" do
      @contact.new?.should be_true
    end

    it "should not be changed" do
      @contact.changed?.should be_false
    end

    it "should have no groups" do
      @contact.groups.should be_empty
    end

    it "should be possible to set the default email address" do
      @contact.email = 'foo@bar.com'
      @contact.emails['foo@bar.com'].should be_primary
      @contact.emails.size.should == 1
    end

    it "should provide access to the contact's primary email address" do
      @contact.email.should be_nil
      @contact.email = 'foo@bar.com'
      @contact.email.should == 'foo@bar.com'
    end

    describe "when updating" do
      it "should update the title-tag" do
        @contact.xml.at('./atom:title').should be_nil
        @contact.title = 'foo'
        @contact.title.synchronize
        @contact.xml.at('./atom:title').content.should == 'foo'
      end
    end
  end

  describe "operations" do
    before(:each) do
      @contact = GoogleContacts::Contact.new(wrapper)
      @root = @contact.xml.document.root
    end

    describe "on groups" do
      before(:each) do
        @groups = [stub('group1', :href => 'foo'), stub('group2', :href => 'bar')]
      end

      it "should be possible to add an array of groups" do
        @contact.groups += @groups
        @contact.groups.should == ['foo', 'bar'].sort
      end

      it "should be possible to add an array of urls" do
        @contact.groups += ['foo', 'bar']
        @contact.groups.should == ['foo', 'bar'].sort
      end

      describe "with initial content" do
        before(:each) do
          @contact.groups = ['foo', 'bar', 'quux']
        end

        it "should be possible to remove an array of groups" do
          @contact.groups -= @groups
          @contact.groups.should == ['quux']
        end

        it "should be possible to remove an array of urls" do
          @contact.groups -= ['foo', 'bar']
          @contact.groups.should == ['quux']
        end
      end
    end
  end
end
