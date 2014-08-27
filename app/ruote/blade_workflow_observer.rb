# encoding:utf-8
require 'ruote/util/process_observer'
class BladeWorkflowObserver < Ruote::ProcessObserver
   # override initialize to warm-up a websocket client
   # def initialize(context, options={})
   #   super
   #   @client = WebsocketClient.new()
   # end

   # tell the listeners that a new process launched
   def on_launch(wfid, info)
     puts "#{log_prefix(wfid)} - launching Process"
   end

   # tell the listeners that a new process ended
   def on_end(wfid)
     puts "#{log_prefix(wfid)} - Process ended"
   end

   def on_dispatch(wfid, info)
     wi = info[:workitem]

     puts "#{log_prefix(wfid)} - #{wi.wf_name}: #{target_info(wi)} 派发到 => #{wi.participant_real_name}"
   end

   def on_receive(wfid, info)
     wi = info[:workitem]
     puts "#{log_prefix(wfid)} - #{wi.wf_name} - #{target_info(wi)}: 接收自 <= #{wi.participant_real_name}"
   end

   def on_cancel(wfid, info)
     puts "#{log_prefix(wfid)} - cancelled"
   end

   def on_kill(wfid, info)
     puts "#{log_prefix(wfid)} - killed"
   end

   private
   def target_info(workitem)
     "#{workitem.target.try(:name)}(Id:#{workitem.target.id})"
   end

   def log_prefix(wfid)
     "[#{BladeUtil.formatted_timestamp} #{wfid}]"
   end
end
