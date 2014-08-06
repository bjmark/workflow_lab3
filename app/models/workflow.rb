class Workflow < ActiveRecord::Base
  belongs_to :final_user, :class_name => 'User'
  has_many :user_workflow_results

  scope :project_like, 
    lambda {|word| word.blank? ? where('') : where('project like ? or workflow_name like ?',"%#{word}%","%#{word}%")}

  def self.target_name(obj)
    case obj
    when Project
      target = project = obj.name
    when CashPosition
      target = project = obj.project.name
    when DisbursementApplication
      target = project = obj.cash_position.project.name
    when Payment
      target = project = obj.disbursement_application.cash_position.project.name
    when ContractApplication, ContractCloseApplication
      target = project = obj.financial_term.owner.name
    when Factoring
      target = "#{obj.factoring_date}保理(#{obj.factoring_type.name})#{obj.amount}"
      a = []
      obj.financial_terms.each {|e| a << e.owner.name}
      project = a.join(',') 
    when FiveLevelClassification
      target = project = obj.project.name
    when IrRentedInspection
      target = project = obj.project.name
    else
      raise 'invalid target'
    end

    [target,project]
  end
end
