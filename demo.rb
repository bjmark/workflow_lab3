workflow = Workflow.find(1)
wfid = RuoteKit.engine.launch(workflow.definition)
puts "wfid = #{wfid}"

