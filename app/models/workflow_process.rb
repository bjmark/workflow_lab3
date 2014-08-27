# encoding: utf-8
class WorkflowProcess
  attr_accessor :workflow, :target, :user, :message

  def initialize(workflow, target, user)
    @workflow = workflow
    @target = target
    @user = user
    @message = nil
  end

  def launch
    target.before_workflow_launch(workflow, user)
    return false if target.errors.any?

    target.transaction do
      begin
        target.on_workflow_launch

        wfid = RuoteKit.engine.launch(
          workflow.definition,
          # workitem fields
          {
            :decision => nil,
            :return_to => nil,
            :not_ok => false,
          },
          # process variables
          {
            :workflow_id => workflow.id,
            :initiator => {
              :user_id => user.id,
              :business_department_id =>  user.business_department.try(:id)
            },
            :target => {
              :type => target.class.to_s,
              :id => target.id
            },
            # TODO: move the following to Workflow def.
            :form => "overview"
        })

        # _IMPORTANT_ NOTE: somehow, the just launched Ruote workflow process
        # _CANNOT_ be obtained by calling RuoteKit.engine.processes(wfid)
        # so cannot rely on calling the :original_tree method of the
        # just launched process.
        ProcessJournal.create!(
          :workflow_id => workflow.id,
          :wfid => wfid,
          :original_tree => workflow.tree_json,
          :user_id => user.id,
          :comments => '',
          :workflow_action => '发起流程',
          :owner_type => target.class.to_s,
          :owner_id => target.id,
        )

        WorkflowResult.create!({
          :workflow_id => workflow.id,
          :wfid => wfid,
          :final_user_id => user.id,
          :process_at => Time.now,
          :target_type => target.class.to_s,
          :target_id => target.id,
        })

        target.after_workflow_launch(workflow, user)
      rescue Exception => e
        # killing the process if it's launched already.
        # kill rather than cancel since we don't want :on_cancel to be called.
        # We are just killing a ill-behaving Ruote process
        RuoteKit.engine.kill_process(wfid) if wfid

        @message = "#{workflow.name}发起失败: #{e.message}。请通知管理员检查系统日志。"
        backtrace = e.backtrace.join("\n")
        Rails.logger.error "#{@message}"
        Rails.logger.error "  Ruote process #{wfid} killed"
        Rails.logger.error "  Error:#{e.message}"
        Rails.logger.error "  Target: #{target.class.to_s} (ID: #{target.id})"
        Rails.logger.error "  User: #{user.name}"
        Rails.logger.error "  Backtrace: #{backtrace}"

        # this rollback raise will NOT actually raise an error
        # it simply rolls back the TX and jumps out of the
        # TX's block.
        target.errors.add(:workflow, @message)
        raise ActiveRecord::Rollback
        return false
      end
    end

    # return false if target.errors.any?

    # it could take a while for the just launched workflow process
    # to show up in the user's queue
    i = 0
    if !Ruote::Workitem.for_user(user).map{ |r| r.target }.include? target and i != 4
      sleep(0.5)
      i += 1
    end

    name = "#{target.name}的#{workflow.name}"
    if i < 4
      @message = "#{name}流程已成功发起！"
    else
      @message = "#{name}已成功添加到流程待办事项队列，稍后请刷新！"
    end

    true
  end
end
