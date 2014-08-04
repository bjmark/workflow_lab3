# -*- encoding: utf-8 -*-
  namespace :ruote do
    desc 'Run a worker thread for ruote'
    task :run_worker => :environment do
      RuoteKit.run_worker(RUOTE_STORAGE)
    end

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
