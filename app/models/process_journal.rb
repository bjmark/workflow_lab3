# -*- encoding: utf-8 -*-
class ProcessJournal < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :user
  belongs_to :role, :class_name => 'Role', :foreign_key => :as_role_id
  belongs_to :owner, :polymorphic => true

  #validates :workflow,   :presence => true
  #validates :ok,         :presence => true
  validates :owner_type, :presence => true
  validates :owner_id,   :presence => true

  scope :for_workitem, lambda { |wfid| where("wfid = ?", wfid) }
  
  scope :proceed, lambda {
    where("process_journals.workflow_action in ('proceed') ")
  }
  #def self.for_wfids(wfids)
    #self.where("wfid in ?", wfids)
  #end
end
