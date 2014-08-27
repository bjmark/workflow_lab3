# -*- encoding: utf-8 -*-
require 'tempfile'

module BladeUtil
  def self.db_backup(date, options = {})
    hash = YAML.load(File.new(File.join(Rails.root, 'config', 'database.yml')))
    host = hash[Rails.env]['host']
    database = hash[Rails.env]['database']
    username = hash[Rails.env]['username'] 
    password = hash[Rails.env]['password']

    surfix = options[:surfix]
    surfix = [date.to_s, surfix].compact.join('_')

    dir = options[:dir]
    dir ||= File.join(Rails.root, 'database_backup')
    back_file = File.join(Rails.root, 'database_backup', "#{database}_#{surfix}")

    cmd = "mysqldump #{database} -u #{username} "
    cmd << "-p#{password} " unless password.try(:strip).blank?
    cmd << "-h #{host} " unless host.try(:strip).blank? 
    cmd << "| gzip - > #{back_file}.sql.gz"
    cmd << "  2>&1"

    # need to use back-tick to capture both command output and return status
    output = `#{cmd}`

    unless $?.success?
      raise "数据库备份出错: #{output}\n#{cmd}"
    end
  end

  def self.execute_sql_file(path)
    begin
      ActiveRecord::Base.connection.begin_db_transaction
      File.read(path).split(';').each do |sql|
        ActiveRecord::Base.connection.execute("#{sql}\n") unless sql.blank?
      end
      ActiveRecord::Base.connection.commit_db_transaction
    rescue ActiveRecord::StatementInvalid
      ActiveRecord::Base.connection.rollback_db_transaction()
      raise
    end
  end

  def self.print_pdf(filename)
    cmd = "lpr #{filename}"
    output = `#{cmd}`

    unless $?.success?
      raise "文件打印出错: #{output}\n#{cmd}"
    end
  end

  def self.gen_sn
    self.timestamp + (rand * 10000).to_i.to_s
  end

  def self.timestamp
    Time.now.strftime("%Y%m%d%H%M%s")
  end

  def self.datestamp
    Time.now.strftime("%Y-%m-%d")
  end

  def self.formatted_timestamp
    Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  class MultiIO
    def initialize(*targets)
       @targets = targets
    end

    def write(*args)
      @targets.each {|t| t.write(*args)}
    end

    def close
      @targets.each(&:close)
    end
  end

  # name:
  #   - day_end
  #   - day_handle
  def self.create_logger(task_type)
    logfile = "#{Rails.root}/log/#{task_type}/#{task_type}_#{self.datestamp}.log"

    dir = File.dirname(logfile)

    unless File.directory?(dir)
      FileUtils.mkdir_p(dir)
    end

    logger = Logger.new(MultiIO.new(STDOUT, File.open(logfile, "a")))
    logger.level = Logger::DEBUG

    # singleton method to add timestamp automatically
    def logger.log(msg, level = nil)
      ts = BladeUtil.formatted_timestamp
      case level
      when :info
        self.info "[#{ts}] - #{msg}"
      when nil, :debug
        self.debug "[#{ts}] - #{msg}"
      when :fatal
        self.fatal "[#{ts}] - #{msg}"
      else
      end
    end

    logger
  end
end
