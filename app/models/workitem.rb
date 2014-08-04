# -*-_ encoding: utf-8 -*-
#
# Simply opening the ruote workitem class to add some things specific
# to arts (and ActiveModel).
#
class Ruote::Workitem
  #include ActiveModel::Naming
  #include ActiveModel::Validations

  # returns the corresponding Ruote process
  def process_tree_json
    RuoteKit.engine.process(self.wfid).current_tree.to_json
  end

  def task
    params['task']
  end

  def participant_name=(name)
    @h['participant_name'] = name
  end

  def initiator
    init_id = self.fields["initiator"]["user_id"]
    init_id.blank? ? nil : User.find(init_id)
  end

  def business_department
    dept_id = self.fields["initiator"]["business_department_id"]
    dept_id.blank? ? nil : Department.find(dept_id)
  end

  def target
    target = self.fields["target"]
    #target["type"].camelize.constantize.find(target["id"])
    target["type"].camelize.constantize.where(:id => target["id"]).first
  end
=begin
  def self.for_current_user
    self.for_user(current_user)
  end
=end
  def self.for_user(user)
    if user.class == String
      user = User.find_by_login(user)
    end

    if !user || user.class != User
      return []
    end

    # _NO_: we don't want the "admin" to have access to all workitems
    # return RuoteKit.engine.storage_participant.all if user.admin?

    # note : ruote 2.1.12 should make it possible to write
    #
    #   RuoteKit.engine.storage_participant.by_participant(
    #     [ username, user.groups, 'anyone' ].flatten)
    #
    # directly.

    workitems = []
    #workitems << RuoteKit.engine.storage_participant.by_participant(user.login)
    #return workitems if workitems.empty?

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
          if workitem.fields["initiator"]["user_id"] == user.id
            workitems << workitem
          end
        end
      when "business_dept_head"
        workitems_via_roles.each do |workitem|
          if workitem.fields["initiator"]["business_department_id"] == user.business_department.id
            workitems << workitem
          end
        end
      else
        workitems << workitems_via_roles
      end
    end
    workitems.flatten.compact.sort do |a, b|
      b.fields["dispatched_at"] <=> a.fields["dispatched_at"]
    end
  end

  # check if a workitem belongs to a user
  def belongs_to?(user)
    self.class.for_user(user).include?(self)
  end

  # Chinese name (role.name) this workitem is currently in the hand's of
  def current_position
    if self.participant_name != 'completer'
      role = Role.find_by_code(self.participant_name)
      if !role
        raise "系统中找不到代码为#{participant_name}的角色/岗位, 请通知系统管理员。"
      else
        role.name
      end
    else
      ''
    end
  end

  def dispatch_time
    Time.parse(self.fields["dispatched_at"]).beijing_time
  end

  def to_param
    fei.sid
  end
end
