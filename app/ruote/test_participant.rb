#encoding:utf-8
class TestParticipant
	include Ruote::LocalParticipant

	def on_workitem
		ref = workitem.fields['params']['ref']
		Log("workflow_test", "#{ref} at #{Time.now} #{Process.pid}")
		sleep(1)
		
		if ref == 'test3' 
			test_number = (workitem.fields['test_number'] or 0)
			test_number += 1
			test_number %= 1000
			
      Log("workflow_test", test_number.to_s.center(20,'*'))
			
			workitem.fields['test_number'] = test_number
			workitem.command = 'rewind'
		end
		reply
	end
end


