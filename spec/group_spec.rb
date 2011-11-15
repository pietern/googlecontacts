require "spec_helper"

describe GoogleContacts::Group do
  before(:each) do
    entries = parsed_asset("groups_full").search("feed > entry")
    @groups = entries.map { |entry| GoogleContacts::Group.new(wrapper, entry) }
    @group  = @groups.first
  end

  it "should know its href" do
    @group.href.should == "http://www.google.com/m8/feeds/groups/jo%40gmail.com/base/6"
  end

  it "should initialize the title tag" do
    @group.title.should == "System Group: My Contacts"
  end

  it "should know when it is a system group" do
    @groups[0].system_group?.should be_true
    @groups[1].system_group?.should be_false
  end

  it "should initialize extended properties" do
    @group[:foo].should == "bar"
  end
end
