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


  specify "has_many :agent_relations, :class_name=>'AgentPrincipal', :foreign_key=>'principal_id' " do
    u = User.create!
    ap = AgentPrincipal.new
    ap.principal = u
    ap.save!

    u.agent_relations.count.should == 1
  end


  specify "has_many :agents, :through=> 'agent_relations'" do
    agent = User.create!
    principal = User.create!

    ap = AgentPrincipal.new
    ap.agent = agent
    ap.principal = principal
    ap.save!

    principal.agents.count.should == 1
    agent.principals.count.should == 1
  end
end
