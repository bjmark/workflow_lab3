class Project < ActiveRecord::Base
  include WorkflowTarget

  belongs_to :workflow_status
  belongs_to :handler, :class_name => "User"
  has_many :cash_positions, :dependent => :destroy
  has_many :financial_terms, :as => :owner, :dependent => :destroy
  
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

  def on_workflow_cancel
    self.workflow_status_id = 5
    self.save
  end

end
