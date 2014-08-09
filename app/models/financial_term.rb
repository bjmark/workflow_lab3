class FinancialTerm < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  has_many :contract_applications, :dependent => :delete_all
end
