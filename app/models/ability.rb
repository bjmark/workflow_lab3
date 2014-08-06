# -*- encoding: utf-8 -*-
#
# Ability Alias for Restful actions
#  def default_alias_actions
#    {
#      :read => [:index, :show],
#      :create => [:new],
#      :update => [:edit],
#    }
#  end
#
# 董事长                   =>      board_chairman
# 总裁                     =>      president
#
# 风险管理部审查岗         =>      risk_dept_examiner
# 风险管理部复核岗         =>      risk_dept_reviewer
# 风险管理部资产管理岗     =>      risk_dept_asset_manager
# 风险管理部法务审核岗     =>      risk_dept_legal_examiner
# 风险管理部法务复核岗     =>      risk_dept_legal_reviewer
# 风险管理部负责人         =>      risk_dept_head

# 综合管理部负责人         =>      admin_dept_head

# 计财部核算岗             =>      accounting_dept_accounting_post
# 计财部负责人             =>      accounting_dept_head
# 计财部考核岗             =>      accounting3
#
# 金融市场资金管理岗       =>      capital_manager
# 金融市场部负责人         =>      capital_market_dept_head
#
# 业务部门负责人           =>      business_dept_head
# 业务经理                 =>      business_manager
#
# NOTE: The following roles added on 04/17/2014
# 风险管理部放款审核岗         =>      risk_dept_disbursement_examiner
# 风险管理部放款复核岗         =>      risk_dept_disbursement_reviewer
# 计财部库管员             => accounting_warehouse_keeper
class Ability
  include CanCan::Ability

  def initialize(user)
    user.roles.each do |role|
      send(role.code, user,role) if self.respond_to?(role.code)
    end

    #所有用户都适用的规则
    everyone(user)
  end


  #风险管理部资产管理岗
  def risk_dept_asset_manager(user,role)
    #租后检查
    can :workflow_ir_rented_inspection, IrRentedInspection do |i|
      i.workflow_status.code == "draft"
    end

    #五级分类
    can :workflow_five_level_classification, FiveLevelClassification do |f|
      f.workflow_status.code == "draft"
    end
  end
  

  #业务经理
  def business_manager(user, role)
    #项目变更
    can :workflow_change, Project do |p|
      (p.handler_id == user.id or p.cohandler_id == user.id) and !p.workflow_process_pending?
    end

    #租后检查
    can :workflow_ir_rented_inspection, IrRentedInspection do |i|
      (i.project.handler_id == user.id or i.project.cohandler_id == user.id) and i.workflow_status.code == "draft"
    end

    #五级分类
    can :workflow_five_level_classification, FiveLevelClassification do |f|
      (f.project.handler_id == user.id or f.project.cohandler_id == user.id) and f.workflow_status.code == "draft"
    end
  end

  def everyone(user)
    #起租
    can :workflow_start_rent, FinancialTerm do |ft|
      owner = ft.owner
      owner.class == Project and Tranche.paid?(ft) and
      (owner.handler_id == user.id or owner.cohandler_id == user.id) and
      !ft.start_on_disbursement and
      ["approved","trached_part","trached"].include?(ft.contract_status.code) and
      ft.get_application("start") and ft.start_date > Date.today
    end

    #关闭
    can :workflow_close_rent, FinancialTerm do |ft|
      owner = ft.owner
      owner.class == Project and
      (owner.handler_id == user.id or owner.cohandler_id == user.id) and
      ft.receivable? and ft.get_application("closed") and
      ![1,11,12,2].include?(ft.contract_status_id) #1=草稿,11=已完结,12=结束审签中
    end
  end
end
