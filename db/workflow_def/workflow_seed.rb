# -*- encoding: utf-8 -*-
require "active_record"

path = File.expand_path("../../../config/database.yml", __FILE__)
hash = YAML.load(File.new(path))

mode = ENV['RAILS_ENV']
mode ||= 'development'

ActiveRecord::Base.establish_connection(hash[mode])

class Workflow < ActiveRecord::Base
end

def_files = {
  1 => "合同审签",
  2 => "头寸报备", 
  3 => "放款审批", 
  4 => "合同起租",
  5 => "合同关闭", 
  6 => "资金调拔",
  7 => "合同保理", 
  8 => "租后检查",
  9 => '五级分类1',
  10 => '五级分类2',
  11 => "租后检查2",
  12 => "合同变更",
}

Workflow.delete_all

def_files.each do |k,v|
  path = File.expand_path("../workflow_#{k}.rb", __FILE__)
  File.open(path) do |f|
    Workflow.new do|w|
      w.id = k
      w.name = v
      w.definition = f.read
      w.save!
    end
  end
end
