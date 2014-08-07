class Project < ActiveRecord::Base
  belongs_to :workflow_status
  belongs_to :handler, :class_name => "User"
  
  def add_right(op,role)
  end
  
  def on_workflow_launch
  end
end
