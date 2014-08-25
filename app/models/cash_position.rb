class CashPosition < ActiveRecord::Base
  belongs_to :project
  has_many :disbursement_applications, :dependent => :destroy
  belongs_to :workflow_status
  has_many :process_journals, :as => :owner, :dependent => :destroy

  def add_right(op,role)
  end

  def del_right(op)
  end

  def on_workflow_launch
  end

  def on_workflow_completion(approved, workitem)
  end

  def on_workflow_cancel
    self.workflow_status_id = 5
    self.save
  end

end
