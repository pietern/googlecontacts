require File.dirname(__FILE__) + '/spec_helper'

describe Group do
  before(:each) do
    entries = parsed_asset('groups_full').search('feed > entry')
    @groups = entries.map { |entry| Group.new(wrapper, entry) }
    @group  = @groups.first
  end

  it "should know its id" do
    @group.id.should == 'http://www.google.com/m8/feeds/groups/jo%40gmail.com/base/6'
  end

  it "should know when it is a system group" do
    @groups[0].system_group?.should be_true
    @groups[1].system_group?.should be_false
  end
end