# encoding:utf-8
gfile ||= File.expand_path('../../../Gemfile', __FILE__)
if !File.exists?(gfile)
  raise "can not find at #{gfile}"
end

ENV['BUNDLE_GEMFILE'] = gfile
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis

storage = 
	Ruote::Redis::Storage.new(::Redis.new(:db => 15, :thread_safe => true), {'ruby_eval_allowed' => true })

engine = Ruote::Dashboard.new(storage) 

engine.register do
	participant /test\d+$/, 'TestParticipant'
  participant 'no_op', Ruote::NoOpParticipant
  participant 'right_setter', 'Workflow1RightSetterParticipant'

  # Will do last steps needed upon process completion
  participant 'completer', 'CompletionParticipant'

  # be explicit here, even though StorageParticipant is the default
  catchall Ruote::StorageParticipant
end

