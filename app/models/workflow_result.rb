# encoding: UTF-8
class WorkflowResult < ActiveRecord::Base
  serialize :snapshot, ActiveSupport::HashWithIndifferentAccess
  belongs_to :final_user, :class_name => 'User'
  belongs_to :workflow

  def snapshot
    read_attribute(:snapshot) ||
      write_attribute(:snapshot, ActiveSupport::HashWithIndifferentAccess.new)
  end

  # workflow processes that the user participated
  def self.for_user(user)
    wfids = ProcessJournal.wfids_for_user(user)
    self.where(:wfid => wfids)
  end
end

