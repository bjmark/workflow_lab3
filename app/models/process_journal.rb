# encoding: utf-8
class ProcessJournal < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :user
  belongs_to :as_role, :class_name => 'Role'
  belongs_to :owner, :polymorphic => true

  validates :workflow,   :presence => true
  validates :owner_type, :presence => true
  validates :owner_id,   :presence => true

  scope :for_wfid, lambda { |wfid| where("wfid = ?", wfid) }
  scope :for_user, lambda { |u| where("user_id = ?", u.id) }

  include Filterable
  search_by :wfid, :associations => [:as_role, :user, :workflow]

  # need to should all process_journal records for all workflow processes
  # that the user participated
  def self.all_records_for_user(user)
    wfids = self.wfids_for_user(user)
    ProcessJournal.where(:wfid => wfids)
  end

  def self.wfids_for_user(user)
    self.for_user(user).map(&:wfid).uniq
  end
end
