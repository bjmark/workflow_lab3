# -*- encoding: utf-8 -*-
class WorkflowMarketingRecordHelper < WorkflowHelper
  def prepare_business_dept
    users = Role.where(:code => 'business_dept_head').first.users
    business_depts = users.collect{|e| e.business_department}.uniq
    other_depts = business_depts.select{|e| e != @workitem.business_department }
    @req.instance_variable_set('@other_depts', other_depts)
  end

  def save_business_dept
    return if @req.params['declined'] == 'yes'
    return if @req.params['agreed'] == 'yes'
    @workitem.fields['blade']['other_business_dept_id'] = @req.params['business_dept_id']
  end

  def prepare_business_manager
    dept = Department.find(@workitem.fields['blade']['other_business_dept_id'])
    role = Role.where(:code => 'business_manager').first
    other_dept_business_managers = dept.users & role.users
    @req.instance_variable_set('@other_dept_business_managers', other_dept_business_managers)
  end

  def save_business_manager
    @workitem.fields['blade']['other_dept_business_manager_id'] = @req.params['business_manager_id']
  end
end
