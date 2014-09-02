# encoding: utf-8
#
# Simply opening the ruote workitem class to add some things specific
# to blade and ActiveModel
#
class Ruote::Workitem
  #include ActiveModel::Naming
  #include ActiveModel::Validations

  attr_accessor :blade_errors

  def add_blade_error(key, value)
    @blade_errors ||= Hash.new
    @blade_errors[key] = value
  end

  def process_tree_json
    process.current_tree.to_json
  end

  # returns the corresponding Ruote process
  def process
    RuoteKit.engine.process(self.wfid)
  end

  def task
    params['task']
  end

  #TODO: delegate/Forwardable doesn't quite work since I
  # don't know how/when to initiate the instance variable @process
  def initiator
    self.process.initiator
  end

  def department
    self.process.department
  end

  def business_department
    self.department.business_department? ? department : nil
  end

  def workflow_id
    self.process.workflow_id
  end

  def target
    self.process.target
  end

  def participant_name=(name)
    @h['participant_name'] = name
  end

  def self.for_user(user)
    workitems = []

    user = User.by_login_or_object(user)
    return workitems if !user

    # _NO_: we don't want the "admin" to have access to all workitems
    # return RuoteKit.engine.storage_participant.all if user.admin?

    # note : ruote 2.1.12 should make it possible to write
    #
    #   RuoteKit.engine.storage_participant.by_participant(
    #     [ username, user.groups, 'anyone' ].flatten)
    #
    # directly.

    # workitems via explicit user login
    #workitems << RuoteKit.engine.storage_participant.by_participant(user.login)

    # the following two roles needs special treatment
    #   :business_manager: should receive only workitems initiated by himself/herself
    #   :business_dept_head
    #
    # role_code is the english name for the role
    # for example, "业务经理"'s code is "business_manager"
    roles = user.roles.map(&:code)
    roles.each do |role_code|
      workitems_via_roles = []
      workitems_via_roles << RuoteKit.engine.storage_participant.by_participant(role_code)
      workitems_via_roles = workitems_via_roles.flatten.compact
      case role_code
      when "business_manager"
        workitems_via_roles.each do |workitem|
          workitems << workitem if workitem.initiator == user
        end
      when "business_dept_head"
        workitems_via_roles.each do |workitem|
          if workitem.business_department == user.business_department
            workitems << workitem
          end
        end
      else
        workitems << workitems_via_roles
      end
    end

    workitems = workitems.flatten.compact
    
    #check if sending to specific user
    workitems = workitems.select do |wi|
      _tag = wi.params['tag']
      receiver_id = "#{_tag.gsub('.','-')}_user_id"
      !(wi.fields['blade'][receiver_id]) or (wi.fields['blade'][receiver_id].to_i == user.id)
    end

    workitems.sort do |a, b|
      b.fields["dispatched_at"] <=> a.fields["dispatched_at"]
    end
  end

  def as_role
    Role.where(:code => self.participant_name).first
  end

  # check whether a workitem belongs to a user
  def belongs_to?(user)
    self.class.for_user(user).include?(self)
  end

  # Chinese name (role.name) this workitem is currently in the hand's of
  def participant_real_name
    real_name(self.participant_name)
  end

  def prev_participant_real_name
    real_name(self.prev_participant)
  end

  alias :current_position :participant_real_name

  def dispatch_time
    Time.parse(self.fields["dispatched_at"]).beijing_time
  end

  def to_param
    fei.sid
  end

  # the following are shortcuts to params in articipant expression
  # return_to :tag in the workflow
  def return_to
    self.fields["return_to"]
  end

  def dispatch?
    self.params['dispatch_to'] ? true : false
  end

  def can_delegate?
    self.params['can_delegate_to'] ? true : false
  end

  def custom_fields
    Array(params['custom_fields'])
  end

  # targt object's attributes that can be in-place edited
  # in Workitem's edit view
  def editable_attributes
    open_edit = params['open_edit']
    open_edit ? [] : Array(open_edit['attributes'])
  end

  # targt object's association objects that can be edited, usually
  # by linking to the object's edit view
  def dispatch_to_role
    dispatch_to = self.params['dispatch_to']
    return nil if !dispatch_to

    Role.where(:code => dispatch_to['role']).first
  end

  def dispatch_to_users(user)
    user.users_with_role_in_my_department(self.dispatch_to_role)
  end

  def can_delegate_to_role
    can_delegate_to = self.params['can_delegate_to']
    return nil if !can_delegate_to

    Role.where(:code => can_delegate_to['role']).first
  end

  def can_delegate_to_users(user)
    user.users_with_role_in_my_department(self.can_delegate_to_role)
  end

  # TODO: may not need this anymore. remove
  def validate
    self.params['validate']
  end

  # added to get bigger picture of the whole workflow
  # TODO: not fully implemented yet
  def next_participant
    raise "Workitem#next_participant Not fully implemented yet!"
    # exp = RuoteKit.engine.fetch_flow_expression(self)
    # parent_exp = RuoteKit.engine.fetch_flow_expression(exp.parent_id)
    #
    # parent_exp.tree[2]
  end

  def prev_participant
    prev_participant_radial[2]
  end

  def top_participant
    _top_tag = top_tag
    return nil unless _top_tag

    p = self.process
    
    r = p.past_tags.find{|e| e[0] == _top_tag}
    top_fei_str = r[1]
    top_fei = Ruote::FlowExpressionId.from_id(top_fei_str)
    expid = top_fei.expid

    # use radial notation to get the previous participant
    exp = Ruote::Reader.to_raw_expid_radial(p.current_tree).find do |e|
      e[1] == expid
    end

    exp[2]
  end

  # for example
  # a -> b -> c -> b
  # when in b, prev_tag is c
  def prev_tag
    tag = ''
    radial = prev_participant_radial[3]
    return tag if !radial

    radial.split(/\s*,\s*/).each do |pair|
      name, tag = pair.split(/: /)
      return tag if name == 'tag' 
    end

    tag
  end

  #pwm new
  # for example
  # a -> b -> c -> b
  # when in b, top_tag is a
  # pls notice the different with pre_tag
  def top_tag
    return nil if self.params['no_back']

    p = self.process          
    cur_tag = self.params['tag']

    past_tags = p.past_tags.collect{|e| e[0] }
    return nil if past_tags.empty?

    unless (past_tags.find{|e| e == cur_tag })
      return past_tags.last
    end

    s = nil
    past_tags.find do |e|
      if e == cur_tag
        true
      else
        s = e
        false
      end
    end

    s
  end

  def task
    self.params["task"]
  end

  # tasks to perform on entry/exit of a participant node
  def on_participant_entry(user)
    begin
      perform_node_task(params["on_entry"])
      grant_edit_in_workflow_abilities(user)
    rescue Exception => e
      raise "执行流程节点转入任务时出错：#{e.message}"
    end
  end

  def on_participant_exit(user)
    begin
      perform_node_task(params['on_exit'])
      revoke_edit_in_workflow_abilities(user)
      gen_reminder
    rescue Exception => e
      raise "执行流程节点转出任务时出错：#{e.message}"
    end
  end

  def gen_reminder
    puts "Generating reminder ..."
    Array(params["reminder"]).each do |role_or_user|
      # TODO: Wei Tian 2014-08-08
    end
  end

  def perform_node_task(tasks)
    Array(tasks).each do |task|
      check = task["check"]
      if check
        if !target.send(check)
          target.errors.add(:workflow, task["message"])
          return false
        end
      end

      perform = task["perform"]
      if perform
        target.send(perform)
        target.errors.add(:workflow, task["message"]) if target.errors.any?
        return false
      end
    end
  end

  def editable_associations
    open_edit = params['open_edit']
    open_edit ? Array(open_edit['associations']) : []
  end

  def grant_edit_in_workflow_abilities(user)
    begin
      editable_associations.each do |association|
        target.send(association).each do |model_obj|
          user.ability.can(:edit_in_workflow, model_obj)
        end
      end
    rescue
      target.errors.add(
        :workflow, "流程中授权#{user.name}修改#{editable_associations}的权限时出错")
    end
  end

  def revoke_edit_in_workflow_abilities(user)
    begin
      editable_associations.each do |association|
        target.send(association).each do |model_obj|
          user.ability.cannot(:edit_in_workflow, model_obj)
        end
      end
    rescue
      target.errors.add(
        :workflow, "流程中取消#{user.name}的修改#{editable_associations}的权限时出错")
    end
  end

  # last person who has handled this workitem, in radial format:
  # [2, "0_0_0", "business_manager", " tag: handler, task: 主协办发起"]
  def prev_participant_radial
    last_tag = self.process.past_tags.last
    return [] if !last_tag

    prev_fei_str = last_tag[1]

    return [] if !prev_fei_str

    prev_fei = Ruote::FlowExpressionId.from_id(prev_fei_str)
    expid = prev_fei.expid

    # use radial notation to get the previous participant
    Ruote::Reader.to_raw_expid_radial(process.current_tree).each do |exp|
      return exp if exp[1] == expid
    end

    []
  end

  # code_name: participant_name in English
  # returns Chinese name of the person or role
  def real_name(code_name)
    user_or_role = User.where(:login => code_name).first
    user_or_role = Role.where(:code => code_name).first if !user_or_role
    if user_or_role
      user_or_role.name
    else
      code_name
    end
  end
end
