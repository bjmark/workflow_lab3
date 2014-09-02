# encoding: utf-8
namespace :ruote do
  desc "Register Ruote Workflow Participant for Blade"
  task :register_blade_participants => :environment do
    RuoteKit.engine.register do
      participant 'no_op', Ruote::NoOpParticipant
      # Will do last steps needed upon process completion
      participant 'completer', 'CompletionParticipant'

      # catchall Ruote::StorageParticipant
      # be explicit here, even though StorageParticipant is the default
      # maybe we can try this instead:
      # catchall BladeParticipant
      catchall Ruote::StorageParticipant
    end
  end

  desc 'Run a (observed) worker thread for ruote: alias of :run_observed_worker'
  task :run_worker => :run_observed_worker

  # task :run_worker
  #   puts "deprecated. please run the following instead:"
  #   puts
  #   puts "  rake ruote:run_observed_worker"
  #   puts
  #   puts "Ruote Workflow Engine Worker Running ..."
  #   RuoteKit.run_worker(RUOTE_STORAGE)
  # end

  desc 'Run a observed worker thread for ruote'
  task :run_observed_worker => :environment do
    ts = BladeUtil.formatted_timestamp
    $stdout.puts "[#{ts}] - Starting Ruote Workflow Engine Worker ..."
    $stdout.puts "[#{ts}] - Services:"
    $stdout.puts "[#{ts}]   - Observer"
    runner = Ruote::Worker.new(RUOTE_STORAGE)
    Ruote::Engine.new(runner, { :join => true }, BladeWorkflowObserver)

    # $stdout.puts "[#{ts}]   - History"
    # Ruote::Engine.new(runner, { :join => true }, BladeWorkflowObserver, Ruote::StorageHistory)
    # we will never reach here
  end

  # TODO: remove this or move it into test task namespace
  # Wei Tian: 2014-08-06
  desc 'Run a thread to handle workflow_storage'
  task :test_handle => :environment do
    while true
      ['storage1','storage2','storage3'].each do |e|
        workitems = []
        workitems << RuoteKit.engine.storage_participant.by_participant(e)
        workitems = workitems.flatten.compact
        workitems.each do |workitem|
          ref = workitem.fields['params']['ref']
          if e == 'storage3'
            test_number = (workitem.fields['test_number'] or 0)
            test_number += 1
            test_number %= 1000

            workitem.fields['test_number'] = test_number
            workitem.command = 'rewind'
          end
          begin
            RuoteKit.storage_participant.proceed(workitem)
          rescue Exception => error
            Log("workflow_storage", error.to_s)
          else
            Log("workflow_storage", "#{ref} at #{Time.now} #{Process.pid}")
            if e == 'storage3'
              Log("workflow_storage", test_number.to_s.center(20,'*'))
            end
          end
        end
      end
      sleep(10)
    end
  end
end
