class Completion2Participant
  include Ruote::LocalParticipant

  def on_workitem
    wr = WorkflowResult.where(:wfid => workitem.wfid).first
    uw = wr.user_workflow_results

    ProcessJournal.where(:wfid => workitem.wfid).order('id asc').all.each do |r| 
      if !uw.any?{|e| e.user_id == r.user_id}
        UserWorkflowResult.create!(:user_id => r.user_id,:workflow_result_id => wr.id)
      end
    end

    reply
  end
end

