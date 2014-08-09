class ContractApplication < ActiveRecord::Base
  belongs_to :financial_term
  belongs_to :user
  belongs_to :workflow_status
  has_many :process_journals, :as => :owner

  def on_workflow_launch
  end

  def on_workflow_completion(approved, workitem)
  end

  def on_workflow_cancel
    self.workflow_status_id = 5
    self.save
  end

  def bypass_validate(s)
    true
  end
end
