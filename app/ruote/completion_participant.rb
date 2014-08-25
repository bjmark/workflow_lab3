# -*-_ encoding: utf-8 -*-
class CompletionParticipant
  include Ruote::LocalParticipant

  def on_workitem
    target = workitem.target
    raise 'invalid target' if !target

    case workitem.fields["ok"] 
    when "1" # => :approved
      target.on_workflow_completion(true, workitem)
      ok = true
      workflow_action = '通过'
    when "2"
      target.on_workflow_cancel
      workflow_action = '取消'
    else # => :declined
      target.on_workflow_completion(false, workitem)
      ok = false
      workflow_action = '否决'
    end

    w = WorkflowResult.where(:wfid => workitem.wfid).first
    unless w.blank?
      w.result = workflow_action
      w.finish = 'y'
      w.save!
    end

    reply
  end
end
