class Project < ActiveRecord::Base
  belongs_to :workflow_status
  belongs_to :handler, :class_name => "User"
  
  def add_right(op,role)
  end

  def del_right(op)
  end
  
  def on_workflow_launch
  end

  def business_contract_exist?
    true
  end

  def on_workflow_completion(approved, workitem)
  end
end
