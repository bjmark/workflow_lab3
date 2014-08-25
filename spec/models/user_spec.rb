require 'spec_helper'

describe User do
  specify do
    #u = User.new
    #u.save.should be_true
    u = User.create!

    d = Department.new
    d.save.should be_true

    u.departments << d
    u.departments.count.should == 1
    
    u.business_department.should be_false

    d.business_department = true
    d.save

    u.business_department.should be_true
  end
end
