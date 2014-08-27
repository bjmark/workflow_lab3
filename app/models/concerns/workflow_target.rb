# encoding: utf-8

# Module containing Workflow/Process related concerns
#
# Usage:
# In model:
#   class Project
#     include Workflowable
#     ...
#    end
#
module WorkflowTarget
  extend ActiveSupport::Concern

  module ClassMethods
  end

  # status_is? is defined in ModelObjectStatus
  def workflow_status_is?(*status_code)
    self.status_is?(:workflow_status, status_code)
  end

  # there should be only one WorkflowProcess running against self
  # but if there are more than one, this returns them all
  def current_workflow_processes
    wf_processes = []
    RuoteKit.engine.processes.each do |wfp|
      wf_processes << wfp if wfp.target == self
    end

    wf_processes
  end

  def kill_pending_processes
    current_workflow_processes.each do |wfp|
      RuoteKit.engine.kill_process(wfp.wfid)
    end
  end

  # workflows that has my model defined as :target_model
  def targeted_workflows
    Workflow.for_target_model(self.class)
  end

  # NOTE: this is generic regardless of workflow
  # a generic checking regardless of workflow
  def workflow_launchable?
    !workflow_status_is?(:pending) && current_workflow_processes.empty?
  end

  def hhash
    read_attribute(:hhash) || write_attribute(:hhash, {})
  end

  # workflow process life cycle hook
  def before_workflow_launch(workflow, user)
    #raise "Must implement in target model!"
  end

  def on_workflow_launch
    status_id = "#{model_status_attr_name}_id"

    self.hhash['backup_status'] = {
      "#{status_id}" => self.send(status_id),
      'workflow_status_id' => self.workflow_status_id
    }

    self.set_association_by_code(model_status_attr_name, :pending)
    self.set_association_by_code(:workflow_status, :pending)
    self.save!
  end

  def after_workflow_launch(workflow, user)
  end

  # restore status when started the workflow
  def on_workflow_cancel
    restore_status
  end

  def on_workflow_completion(workitem)
    #raise "Need to be implemented by target model"
  end

  # NOTE:
  # This is meant for debugging/testing purpose.
  # use with _CAUTION_
  def reset_workflow_status
    self.set_association_by_code(model_status_attr_name, :draft)
    self.set_association_by_code(:workflow_status, :draft)
    self.save!
  end
  # end of Workflow process life-cycle related logic

  # 是否可以上传合同
  # TODO: need to move to project model.
  def contract_upload_allowed?(user)
    message = false
    # 找到审查岗的操作记录
    risk_dept_legal_examiner_step = ProcessJournal.where(:owner_type => 'Project', :owner_id => self.id, :workflow_action => '下一步:法务复核').last
    # 找到这个项目审签流程的所有记录
    step_arr, temp_arr = ProcessJournal.where(:owner_type => 'Project', :owner_id => self.id), []
    # 如果项目没有发起审签不能上传合同
    return false if step_arr.blank?
    # 剔除上一步的操作
    step_arr.each do |s|
      temp_arr << s if !(s.workflow_action =~ /上一步/)
    end
    # 找到最后一步操作
    last_step = temp_arr.last
    have_permission_step = [
      '下一步:法务复核',
      '下一步:风险部负责人',
      '下一步:业务核算岗',
      '下一步:计财部负责人',
      '下一步:业务经理检查会办结果',
      '下一步:业务部负责人检查会办结果',
      '下一步:风险管理部负责人检查会办结果',
      '下一步:分管副总裁','下一步:总裁','终审通过'
    ]

    if last_step.workflow_action == '下一步:法务审核岗'
      message = true if user.roles.map{ |r| r.code }.include?('risk_dept_legal_examiner')
    else
      return false if risk_dept_legal_examiner_step.blank?
      if have_permission_step.include?(last_step.workflow_action)
        message = risk_dept_legal_examiner_step.user == user
      end
    end
    message
  end

  # end of Workflow process life-cycle related logic

  # TODO: the following needs refactoring
  # workflow related rights
  def add_right(op, role)
    h = self.hhash
    h['overview'] ||= {}
    h['overview'][op] = role
    self.update_attribute(:hhash, h)
  end

  def del_right(op)
    h = self.hhash
    return if h['overview'].blank?

    op = [op] if op.instance_of?(String)
    op.each do |e|
      h['overview'].delete(e)
    end

    self.update_attribute(:hhash, h)
  end

  def has_right?(op,u)
    return false if self.hhash['overview'].blank?
    codes = u.roles.collect{|e| e.code}
    codes.include?(self.hhash['overview'][op])
  end

  # this is only for test
  def bypass_validation(validate_name)
    bypass_arr = hhash['bypass_validate']
    bypass_arr ? bypass_arr.include?(validate_name) : false
  end

  private
  def model_status_attr_name
    "#{self.class.to_s.underscore}_status".to_sym
  end

  def set_approved_statuses
    self.set_association_by_code(model_status_attr_name, :approved)
    self.set_association_by_code(:workflow_status, :approved)
  end

  def set_declined_statuses
    self.set_association_by_code(model_status_attr_name, :declined)
    self.set_association_by_code(:workflow_status, :approved)
  end

  def restore_status
    self.sql_update(hhash['backup_status'])
  end
end
