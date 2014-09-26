class AgentRelation < ActiveRecord::Base
  belongs_to :agent, :class_name => 'User'
  belongs_to :principal, :class_name => 'User'
end
