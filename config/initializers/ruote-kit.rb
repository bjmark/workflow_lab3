# make changes when needed
#
# you may use another persistent storage for example or include a worker so that
# you don't have to run it in a separate instance
#
# See http://ruote.rubyforge.org/configuration.html for configuration options of
# ruote.
require 'redis'
require 'ruote'
require 'ruote-redis'


# load our own Ruote::Workitem extension
require Rails.root.join('app/models/workitem.rb')
require Rails.root.join('app/models/process_status.rb')
require Rails.root.join('app/ruote/completion_participant.rb')

require 'ruote/log/storage_history'

# extend Ruote::Dashboard
module Ruote
  class Engine
    # modify the initializer so it takes a ProcessObserver
    def initialize(worker_or_storage, opts = true, observer = nil, historian = nil)

      @context = worker_or_storage.context
      @context.dashboard = self

      @variables = EngineVariables.new(@context.storage)

      self.add_service('blade_observer', observer) if observer
      self.add_service('history', historian) if historian

      workers = @context.services.select { |ser|
        ser.respond_to?(:run) && ser.respond_to?(:run_in_thread)
      }

      return unless opts && workers.any?

      # let's isolate a worker to join

      worker = if opts.is_a?(Hash) && opts[:join]
        workers.find { |wor| wor.name == 'worker' } || workers.first
      else
        nil
      end

      (workers - Array(worker)).each { |wor| wor.run_in_thread }
      # launch their thread, but let's not join them

      worker.run if worker
      # and let's not return
    end

    # please refer to Ruote::Dashboard#initialize
    def self.create_with_runner_and_observer(runner, observer_class)
      @context = runner.context
      @context.dashboard = self
      @variables = EngineVariables.new(@context.storage)

      self.add_service('blade_workflow_observer', BladeWorkflowObserver)

      workers = @context.services.select { |ser|
        ser.respond_to?(:run) && ser.respond_to?(:run_in_thread)
      }

      # let's isolate a worker to join
      worker = workers.find { |wor| wor.name == 'worker' } || workers.first
      (workers - Array(worker)).each { |wor| wor.run_in_thread }
        # launch their thread, but let's not join them

      worker.run if worker
        # and let's not return
    end

    def kill_all_processes
      processes.each do |process|
        kill(process.wfid)
      end
    end
  end
end

RUOTE_STORAGE = Ruote::Redis::Storage.new(
  ::Redis.new(:db => 14, :thread_safe => true), {
    'ruby_eval_allowed' => true
  })

RuoteKit.engine = Ruote::Engine.new(RUOTE_STORAGE)

# By default, there is a running worker when you start the Rails server. That is
# convenient in development, but may be (or not) a problem in deployment.
#
# Please keep in mind that there should always be a running worker or schedules
# may get triggered to late. Some deployments (like Passenger) won't guarantee
# the Rails server process is running all the time, so that there's no always-on
# worker. Also beware that the Ruote::HashStorage only supports one worker.
#
# If you don't want to start a worker thread within your Rails server process,
# replace the line before this comment with the following:
#
# RuoteKit.engine = Ruote::Engine.new(RUOTE_STORAGE)
#
# To run a worker in its own process, there's a rake task available:
#
#     rake ruote:run_worker
#
# Stop the task by pressing Ctrl+C
# Ruote participant registration has been moved to:
#
#   app/ruote/register_participant.rb
#
# The registration needs to be system-wide and should _NOT_ be done here by each
# individual Rails instance.

# when true, the engine will be very noisy (stdout)
RuoteKit.engine.context.logger.noisy = false
