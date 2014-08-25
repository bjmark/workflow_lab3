# make changes when needed
#
# you may use another persistent storage for example or include a worker so that
# you don't have to run it in a separate instance
#
# See http://ruote.rubyforge.org/configuration.html for configuration options of
# ruote.
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis


# load our own Ruote::Workitem extension
require Rails.root.join('app/models/workitem.rb')
require Rails.root.join('app/models/process_status.rb')
require Rails.root.join('app/ruote/test_participant.rb')
require Rails.root.join('app/ruote/completion_participant.rb')
require Rails.root.join('app/ruote/completion2_participant.rb')
require Rails.root.join('app/ruote/workflow1_right_setter_participant.rb')


#require 'ruote/storage/fs_storage'
#RUOTE_STORAGE = Ruote::FsStorage.new("public/ruote/storage/ruote_work_#{Rails.env}")

RUOTE_STORAGE = Ruote::Redis::Storage.new(
  ::Redis.new(:db => 13, :thread_safe => true), {
    'ruby_eval_allowed' => true })

#RuoteKit.engine = Ruote::Engine.new(Ruote::Worker.new(RUOTE_STORAGE))
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
# Ruote participant registration has been moved to script/workflow/register.rb
# The registration needs to be system-wide and should _NOT_ be done here by each
# individual Rails instance.

# when true, the engine will be very noisy (stdout)
RuoteKit.engine.context.logger.noisy = false
