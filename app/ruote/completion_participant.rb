# encoding: utf-8
class CompletionParticipant < BladeParticipant
  def on_workitem(workitem)
    target = workitem.target

    return handle_invalid_target(workitem) if !target

    workflow_action = ''
    case workitem.fields["decision"]
    when "approved"
      target.on_workflow_completion(true, workitem)
      workflow_action = '通过'
    when "cancelled"
      target.on_workflow_cancel
      workflow_action = '取消'
    when "declined"
      target.on_workflow_completion(false, workitem)
      workflow_action = '否决'
    else
      workflow_action = '未知'
    end

    wfr = WorkflowResult.where(:wfid => workitem.wfid).first
    if wfr
      wfr.result = workflow_action
      wfr.finished = true
      wfr.save!
    end

    reply
  end
end
