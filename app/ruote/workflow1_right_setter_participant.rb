class Workflow1RightSetterParticipant
  include Ruote::LocalParticipant

  def on_workitem
		p = workitem.target
    workitem.fields['params']['add_right'].each do |op,role|
			p.add_right(op,role)
		end
    reply
  end
end

