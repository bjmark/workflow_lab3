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
  end
end
