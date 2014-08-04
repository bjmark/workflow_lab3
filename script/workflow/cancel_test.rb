#encoding:utf-8
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
	Ruote::Redis::Storage.new(::Redis.new(:db => 14, :thread_safe => true), {'ruby_eval_allowed' => true })

engine = Ruote::Dashboard.new(storage) 
status = engine.processes
status.each do |e|
  if e.definition_name == '测试'
		#puts e.inspect
		engine.cancel_process(e.wfid)
	end
end
