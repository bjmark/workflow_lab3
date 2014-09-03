# encoding: utf-8
namespace :blade do
  # desc "打印调息通知书,rake blade:print date='2013-5-23' id='1'"
  # task :print => :environment do
  #   DayEnd.print_pdf(:edate=>ENV[:date], :sql=>ENV['id'])
  # end

  workflows = [
=begin
    :project_approval,
    :cash_position_filing,
    :disbursement_approval,
    :lease_start,
    :lease_end,
    :fund_allocation,
    :factoring,
    :post_start_inspection_1,
    :five_level_classification_1,
    :five_level_classification_2,
    :post_start_inspection_2,
    :lease_change,
=end
    :credit_approval,
    :marketing_record
  ]

  desc "从db/workflow_def/目录下，将文件名为workflow_<流程代码>的流程定义导入系统"
  task :workflow_seed => :environment do
    puts "loading workflow definition into DB..."

    workflows.each do |code|
      wf_def_file = Rails.root.join("./db/workflow_def/workflow_#{code}.rb")
      begin
        wf = Workflow.load_from_file(wf_def_file)
        puts "  #{wf.name} 由文件 #{wf_def_file} 导入成功"
      rescue Exception => e
        puts "  流程定义导入失败(文件名 #{wf_def_file} ): #{e.message}"
      end
    end
    puts "done."
  end

  desc "从db/workflow_def/目录下，根据指明的工作流代码(:code), 将文件名为workflow_<code的流程定义导入系统。\n" <<
  "Usage: rake blade:workflow_update workflow=<workflow_code>"
  task :workflow_update => :environment do
    code = ENV["workflow"]

    if !code
      puts "Usage: rake blade:workflow_update workflow=<workflow_code>"
      puts "  e.g: 用以下命令新建或更新合同审签流程(code: project_approval)"
      puts "       rake blade:workflow_update workflow=project_approval"
      exit
    end

    wf_def_file = Rails.root.join("./db/workflow_def/workflow_#{code}.rb")

    begin
      wf = Workflow.load_from_file(wf_def_file)
      puts "#{wf.name} 由文件 #{wf_def_file} 导入成功"
    rescue Exception => e
      puts "  流程定义导入失败(文件名 #{wf_def_file} ): #{e.message}"
    end
  end
end
