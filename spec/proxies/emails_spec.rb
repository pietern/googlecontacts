require "spec_helper"

describe GoogleContacts::Proxies::Emails do
  describe "with existing entries" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry xmlns:gd="http://schemas.google.com/g/2005">
          <gd:email label="Personal" displayName="Foo Bar"
                    address="foo@bar.example.com" />
          <gd:email rel="http://schemas.google.com/g/2005#home"
                    address="fubar@gmail.com" primary="true"/>
        </entry>
      XML
    end

    it "should initialize on creation" do
      @proxy["foo@bar.example.com"].address .should == "foo@bar.example.com"
      @proxy["foo@bar.example.com"].name    .should == "Foo Bar"
      @proxy["foo@bar.example.com"].label   .should == "Personal"
      @proxy["foo@bar.example.com"].rel     .should be_nil
      @proxy["foo@bar.example.com"]         .should_not be_primary

      @proxy["fubar@gmail.com"    ].address .should == "fubar@gmail.com"
      @proxy["fubar@gmail.com"    ].name    .should be_nil
      @proxy["fubar@gmail.com"    ].label   .should be_nil
      @proxy["fubar@gmail.com"    ].rel     .should == "http://schemas.google.com/g/2005#home"
      @proxy["fubar@gmail.com"    ]         .should be_primary
    end

    it "should be able to return the primary address" do
      @proxy.primary.should == @proxy["fubar@gmail.com"]
    end

    it "should initially be unchanged" do
      @proxy.changed?.should be_false
    end

    describe "should be changed" do
      after(:each) do
        @proxy.changed?.should be_true
      end

      it "when switching primary" do
        @proxy["foo@bar.example.com"].primary!
      end

      it "when modifying name" do
        @proxy["foo@bar.example.com"].name = "Quux"
      end

      it "when modifying rel" do
        @proxy["foo@bar.example.com"].rel = "http://some.rel"
      end

      it "when adding a new address" do
        @proxy << "john@doe.com"
      end

      it "when removing an address" do
        @proxy.delete "foo@bar.example.com"
      end
    end
  end

  describe "without existing entries" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry xmlns:gd="http://schemas.google.com/g/2005">
        </entry>
      XML
    end

    it "should be possible to add email address" do
      lambda {
        @proxy["foo@bar.com"]
      }.should change(@proxy, :size).by(1)

      lambda {
        @proxy << "quux@bar.com"
      }.should change(@proxy, :size).by(1)
    end

    it "should raise when adding a duplicate" do
      @proxy << "quux@bar.com"
      lambda {
        @proxy << "quux@bar.com"
      }.should raise_error
    end

    it "should provide sensible defaults for new addresses" do
      @proxy["john@doe.com"].address.should == "john@doe.com"
      @proxy["john@doe.com"].rel.should == "http://schemas.google.com/g/2005#home"
      @proxy["john@doe.com"].label.should be_nil
    end

    it "should set the first created entry to be primary" do
      @proxy["john@doe.com"].should be_primary
    end

    it "should only allow one entry to be primary" do
      @proxy["john@doe.com"].should be_primary
      @proxy["jane@doe.com"].should_not be_primary
      @proxy["jane@doe.com"].primary!
      @proxy["john@doe.com"].should_not be_primary
      @proxy["jane@doe.com"].should be_primary
    end

    it "should only allow either rel or label to be set" do
      @proxy["john@doe.com"].rel   = "foo"
      @proxy["john@doe.com"].label = "foo"
      @proxy["john@doe.com"].rel.should be_nil

      @proxy["john@doe.com"].label = "foo"
      @proxy["john@doe.com"].rel   = "foo"
      @proxy["john@doe.com"].label.should be_nil
    end

    it "should raise when attempting to modify the address" do
      lambda {
        @proxy["john@doe.com"].address = "foo"
      }.should raise_error(/cannot modify/i)
    end

    it "should allow email addresses to be removed" do
      @proxy << "john@doe.com"
      lambda {
        @proxy.delete("john@doe.com")
      }.should change(@proxy, :size).from(1).to(0)
    end
  end

  describe "synchronize to xml document" do
    before(:each) do
      create_proxy_from_xml <<-XML
        <entry xmlns:gd="http://schemas.google.com/g/2005">
        </entry>
      XML
    end

    it "should clear existing email tags" do
      @proxy << "john@doe.com"
      @parent.should_receive(:remove_xml).with("./gd:email")
      @parent.stub(:insert_xml)
      @proxy.synchronize
    end

    it "should add every email address" do
      @proxy << "john@doe.com"
      @proxy << "jane@doe.com"

      @parent.stub(:remove_xml)
      @parent.should_receive(:insert_xml).
        with("gd:email", include(
          "address" => "john@doe.com",
          "primary" => "true"))
      @parent.should_receive(:insert_xml).
        with("gd:email", include(
          "address" => "jane@doe.com"))
      @proxy.synchronize
    end
  end

  def create_proxy_from_xml(str)
    @parent = stub("parent", :xml => Nokogiri::XML.parse(str).root)
    @proxy  = GoogleContacts::Proxies::Emails.new(@parent)
  end
end
