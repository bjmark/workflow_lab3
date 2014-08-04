#encoding:utf-8
gfile ||= File.expand_path('../../../Gemfile', __FILE__)
if !File.exists?(gfile)
  raise "can not find at #{gfile}"
end

ENV['BUNDLE_GEMFILE'] = gfile
require 'bundler/setup' 
require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis
=begin
执行步骤
(1) after rake ruote:run:woker      
(2) ruby script/workflow_test/launch.rb      
(3) ruby cancel_test.rb        # cancel the test process 
结论：
注册可以一次性执行，现在在启动blade时同时注册8次，会不会有问题？
=end

if ARGV.length != 1
	puts "use: ruby launch workflow_test.rb"
	exit(1)
end

file = ARGV.first

storage = 
  Ruote::Redis::Storage.new(::Redis.new(:db => 14, :thread_safe => true), {'ruby_eval_allowed' => true })

engine = Ruote::Dashboard.new(storage) 

file = File.expand_path("../#{file}", __FILE__)
workflow_t = File.open(file) {|f| f.read} 

engine.launch(workflow_t)



