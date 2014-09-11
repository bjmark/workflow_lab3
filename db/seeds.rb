# -*- encoding: utf-8 -*-

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


Proc.new do
  WorkflowStatus.delete_all
  a = [
    { :id => 1, :code => 'draft',     :name => '草稿' },
    { :id => 2, :code => 'pending',   :name => '审批中' },
    { :id => 3, :code => 'approved',  :name => '已批准' },
    { :id => 4, :code => 'declined',  :name => '已否决' },
    { :id => 5, :code => 'cancelled', :name => '已取消' },
    { :id => 6, :code => 'failed',    :name => '工作流出错' },
  ]

  a.each do |e|
    WorkflowStatus.new do |r|
      r.id = e[:id]
      r.code = e[:code]
      r.name = e[:name]
      r.save
    end
  end

  #roles in workflows

  #workflow1
  #business_manager
  #business_dept_head
  #risk_dept_examiner
  #risk_dept_legal_examiner
  #risk_dept_legal_reviewer
  #risk_dept_head
  #accounting_dept_accounting_post
  #accounting_dept_head
  #vp
  #president
  
  #workflow2
  #business_manager
  #business_dept_head
  #risk_dept_examiner
  #risk_dept_legal_examiner
  #risk_dept_head
  #capital_manager
  #capital_market_dept_head

  #workflow3
  #business_manager
  #business_dept_head
  #risk_dept_disbursement_examiner
  #risk_dept_disbursement_reviewer
  #risk_dept_head
  #capital_manager
  #capital_market_dept_head
  #accounting_dept_accounting_post
  #accounting_dept_head
  #vp
  #president

  #workflow4
  #business_manager
  #business_dept_head
  #risk_dept_examiner
  #risk_dept_head
  #accounting_dept_accounting_post
  #accounting_dept_head

  #workflow5
  #business_manager
  #business_dept_head
  #accounting_dept_accounting_post
  #accounting_dept_head
  #risk_dept_legal_examiner
  #risk_dept_head

  #workflow6
  #capital_manager
  #capital_market_dept_head
  #accounting_dept_accounting_post
  #accounting_dept_head
  
  #workflow7
  #accounting_dept_accounting_post
  #accounting_dept_head

  #workflow8
  #business_manager
  #business_dept_head
  #risk_dept_asset_manager
  #risk_dept_head
  
  #workflow9
  #business_manager
  #business_dept_head
  #risk_dept_asset_manager
  #risk_dept_head

  #workflow10
  #risk_dept_asset_manager
  #risk_dept_head
  
  #workflow11
  #risk_dept_asset_manager
  #risk_dept_head

  #workflow12
  #business_manager
  #business_dept_head
  #risk_dept_examiner
  #risk_dept_legal_examiner
  #risk_dept_legal_reviewer
  #risk_dept_head
  #accounting_dept_accounting_post
  #accounting_dept_head
  #vp
  #president

  #建角色
  Role.delete_all
  h = {
    '董事长' => 'board_chairman',
    '总裁'   => 'president',
    '副总裁'  => 'vp',
    '主任委员' => 'committee_director',
    '评审委员会秘书' => 'committee_secretary',
    '风险管理部审查岗' => 'risk_dept_examiner',
    '风险管理部复核岗' => 'risk_dept_reviewer',
    '风险管理部资产管理岗' => 'risk_dept_asset_manager',
    '风险管理部法务审核岗' => 'risk_dept_legal_examiner',
    '风险管理部法务复核岗' => 'risk_dept_legal_reviewer',
    '风险管理部负责人' => 'risk_dept_head',
    '风险管理部放款审查岗' => 'risk_dept_disbursement_examiner',
    '风险管理部放款复核岗' => 'risk_dept_disbursement_reviewer',
    '综合管理部负责人' => 'admin_dept_head',
    '计财部核算岗' => 'accounting_dept_accounting_post',
    '计财部负责人' => 'accounting_dept_head',
    '计财部考核岗' => 'accounting3',
    '计财部库管员' => 'accounting_warehouse_keeper',
    '金融市场资金管理岗' => 'capital_manager',
    '金融市场部负责人' => 'capital_market_dept_head',
    '业务部门负责人' => 'business_dept_head',
    '业务经理' => 'business_manager',
    '营销管理部负责人' => 'marketing_dept_head',
    '营销管理部业务管理岗' => 'marketing_dept_staff'
  }

  id = 0
  h.each do |name, code|
    id += 1
    Role.new do |r|
      r.id = id
      r.name = name
      r.code = code 
      r.save
    end
  end

  #建部门,只需要业务部
  Department.delete_all

  (1..2).each do |id|
    Department.new do |r|
      r.id = id
      r.name = "业务#{id}部"
      r.business_department = true
      r.save
    end
  end

  #建用户
  User.delete_all

  ['A','B'].each do |e|
    u = User.create(:name => "业务经理#{e}(业务1部)")
    u.roles << Role.where(:code => 'business_manager').first
    u.departments << Department.where(:name => '业务1部')
  end

  u = User.create(:name => "业务部门负责人(业务1部)")
  u.roles << Role.where(:code => 'business_dept_head').first
  u.departments << Department.where(:name => '业务1部')

  ['A','B'].each do |e|
    u = User.create(:name => "业务经理#{e}(业务2部)")
    u.roles << Role.where(:code => 'business_manager').first
    u.departments << Department.where(:name => '业务2部')
  end

  u = User.create(:name => "业务部门负责人(业务2部)")
  u.roles << Role.where(:code => 'business_dept_head').first
  u.departments << Department.where(:name => '业务2部')
  
  u = User.create(:name => "总裁")
  u.roles << Role.where(:code => 'president').first


  u = User.create(:name => "副总裁")
  u.roles << Role.where(:code => 'vp').first


  u = User.create(:name => "主任委员")
  u.roles << Role.where(:code => 'committee_director').first

  #u = User.create(:name => "评审委员会秘书")
  #u.roles << Role.where(:code => 'committee_secretary').first

  ['A','B','C'].each do |e|
    u = User.create(:name => "风险管理部审查岗#{e}")
    u.roles << Role.where(:code => 'risk_dept_examiner').first
    u.roles << Role.where(:code => 'committee_secretary').first
  end
  
  u = User.create(:name => "风险管理部复核岗")
  u.roles << Role.where(:code => 'risk_dept_reviewer').first
  
  u = User.create(:name => "风险管理部法务审核岗")
  u.roles << Role.where(:code => 'risk_dept_legal_examiner').first

  u = User.create(:name => "风险管理部法务复核岗")
  u.roles << Role.where(:code => 'risk_dept_legal_reviewer').first
  
  u = User.create(:name => "风险管理部负责人")
  u.roles << Role.where(:code => 'risk_dept_head').first

  u = User.create(:name => "风险管理部放款审查岗")
  u.roles << Role.where(:code => 'risk_dept_disbursement_examiner').first
  
  u = User.create(:name => "风险管理部放款复核岗")
  u.roles << Role.where(:code => 'risk_dept_disbursement_reviewer').first
  
  u = User.create(:name => "综合管理部负责人")
  u.roles << Role.where(:code => 'admin_dept_head').first
  
  u = User.create(:name => "计财部核算岗")
  u.roles << Role.where(:code => 'accounting_dept_accounting_post').first
  
  u = User.create(:name => "计财部负责人")
  u.roles << Role.where(:code => 'accounting_dept_head').first
  
  u = User.create(:name => "计财部考核岗")
  u.roles << Role.where(:code => 'accounting3').first
  
  u = User.create(:name => "计财部库管员")
  u.roles << Role.where(:code => 'accounting_warehouse_keeper').first
  
  u = User.create(:name => "金融市场资金管理岗")
  u.roles << Role.where(:code => 'capital_manager').first
  
  u = User.create(:name => "金融市场部负责人")
  u.roles << Role.where(:code => 'capital_market_dept_head').first
  
  u = User.create(:name => "营销管理部负责人")
  u.roles << Role.where(:code => 'marketing_dept_head').first
  
  u = User.create(:name => "营销管理部业务管理岗")
  u.roles << Role.where(:code => 'marketing_dept_staff').first
end.call

