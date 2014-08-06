class Project < ActiveRecord::Base
  belongs_to :workflow_status
  def on_workflow_launch
  end
end
