require 'spec_helper'

describe AgentRelation do
  specify 'create' do
    AgentRelation.create!
    AgentRelation.count.should == 1
  end

  specify "belongs_to :agent, :class_name => 'User'" do
    u = User.create!
    ar = AgentRelation.new
    ar.principal = u
    ar.save!

    ar.persisted?.should be_true
    u.agent_relations.count.should == 1
  end
  
  specify "has_many :principal_relations, :foreign_key => 'principal_id'" do
    u = User.create!
    ar = AgentRelation.new
    ar.agent = u
    ar.save!

    ar.persisted?.should be_true
    u.principal_relations.count.should == 1
  end
  
end
