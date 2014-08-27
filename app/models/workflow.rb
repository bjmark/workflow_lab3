# encoding: utf-8
class Workflow < ActiveRecord::Base
  extend Ext::Constantifier

  has_many :workflow_results
  has_many :process_journals

  include Filterable
  search_by :name, :code

  attr_protected :name, :code, :target_model, :version
  validates :definition, :presence => true

  validate :apply_business_rules

  # aviable workflows that has model_klass as its target_model
  def self.for_target_model(model_klass)
    self.where(:target_model => model_klass)
  end

  # if the specific workflow already exists, update;
  # otherwise, create.
  def self.load_from_file(filename)
    # code should matching our workflow definiton file
    # naming convention
    code_in_filename =
      self.get_workflow_code_from_definition_filename(filename)

    if code_in_filename.blank?
      raise "Filename #{filename} not in workflow_<code>.rb format"
    end

    begin
      File.open(filename) do |f|
        wf_def = f.read
        tree = Ruote::Reader.read(wf_def)

        code = tree[1]["code"]
        if !code
          raise "Invalid workflow definition in #{filename}: :code not defined."
        end

        # code should matching our workflow definiton file
        # naming convention
        if code != code_in_filename
          raise ":code in definition does NOT match :code in filename"
        end

        workflow = self.find_by_code(code)
        workflow = Workflow.new if !workflow

        workflow.definition = wf_def

        # validation (#apply_business_rules), which does all the necessary
        # parsing and setup, will be called automatically
        workflow.save!
      end
    rescue Errno::ENOENT => e
      raise "File #{filename} error: #{e.message}"
    rescue Exception => e
      raise "Error loading workflow from file #{filename}: #{e.message}"
    end

    self
  end

  def tree
    if @tree.blank?
      begin
        @tree = Ruote::Reader.read(definition)
      rescue Exception => e
        raise "流程定义非法: #{e.message}"
      end
    end

    @tree
  end

  def tree_json
    Rufus::Json.encode(tree)
  end

  # Makes sure the 'definition' column contains a string that is Ruby code.
  def rubyize!
    self.definition = Ruote::Reader.to_ruby(tree).strip
  end

  private
  def self.get_workflow_code_from_definition_filename(filename)
    base = File.basename(filename)
    trash, code_in_filename = base.split(/workflow_|\./)

    code_in_filename ? code_in_filename : ''
  end

  # the header section of the Ruote.process_definition, where
  # :name, :revision, :target_model, etc. are defined
  def def_header
    tree[1]
  end

  def apply_business_rules
    [:code, :name, :version, :target_model].each do |required_tag|
      if !def_header[required_tag.to_s]
        raise "流程定义非法: 流程 :#{required_tag} 未定义!"
      end
    end

    self.code = def_header["code"]
    self.name = def_header["name"]
    self.version = def_header["version"]
    self.target_model = def_header["target_model"]

    begin
      self.target_model.camelize.constantize
    rescue Exception => e
      raise "流程目标(target_model)定义非法: #{target_model}不存在!"
    end

    begin
      self.rubyize!
    rescue Exception => e
      raise "流程非法(#rubyize! failed): #{e.message}"
    end
  end
end
