# opening up Ruote::ProcessStatus
class Ruote::ProcessStatus
  # workitems that has been touched by current_user
  # and are still in workflow process, but not in current_usre's queue anymore.
  # In other words, they are in somebody else's queue.
  def self.touched_by_user(user)
    @processes = []
    @workitems_in_user_queue = Ruote::Workitem.for_user(user)

    if @workitems_in_user_queue.empty?
      RuoteKit.engine.processes.each do |p|
        @processes << p if ProcessJournal.exists?(:wfid => p.wfid, :user_id => user.id)
      end
    else
      RuoteKit.engine.processes.each do |p|
        # excluding processes that have workitems in user's queue
        count_the_process = true
        @workitems_in_user_queue.each do |wi|
          if p.workitems.include?(wi)
            count_the_process = false
            break
          end
        end
        if count_the_process
          @processes << p if ProcessJournal.exists?(:wfid => p.wfid, :user_id => user.id)
        end
      end
    end

    # minus workitems that are in the user's queue
    @processes.sort do |a, b|
      b.last_active <=> a.last_active
    end
  end

  # the participant name the workitem is currently in
  # normally (without concurrence) there should be only one workitem
  # when querying Ruote::ProcessStatus.workitems
  def current_position
    self.workitems.first.try(:current_position)
  end

  # workflow process target, for example, some project
  def target
    target = self.variables["target"]

    # CANNOT use find here since find will raise error if :id doesn't exist
    target["type"].camelize.constantize.where(:id => target["id"]).first
  end

  def workflow_id
    self.variables["workflow_id"]
  end


  def initiator
    init_id = self.variables["initiator"]["user_id"]
    init_id.blank? ? nil : User.where(:id => init_id).first
  end

  def department
    dept_id = self.variables["initiator"]["business_department_id"]
    dept_id.blank? ? nil : Department.where(:id => dept_id).first
  end
end
