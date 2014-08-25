class UserWorkflowResult < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow_result

  def self.check_and_create(workflow_result_id,user_id)
    if where(:workflow_result_id => workflow_result_id, :user_id => user_id).blank?
      create!(:workflow_result_id => workflow_result_id, :user_id => user_id)
    end
  end
end
