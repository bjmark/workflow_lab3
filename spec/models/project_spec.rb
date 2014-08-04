require 'spec_helper'

describe Project do
  specify do
    Project.new.save
    Project.count.should == 1
  end
end
