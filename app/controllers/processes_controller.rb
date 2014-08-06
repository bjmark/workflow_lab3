# -*-_ encoding: utf-8 -*-
# This is for list processes that contains workitems that the current user
# has worked on.
# For application wide Ruote::ProcessStatus related resource controller,
# use the build in Rack URL: http://host/_ruote
#
class ProcessesController < ApplicationController
  #load_and_authorize_resource

  def index
    workflow_results = current_user.workflow_results.project_like(params[:search]).where(:finish => 'n')
    @processes = []
    workflow_results.each do |w|
       p = RuoteKit.engine.process(w.wfid)
       @processes << p if p
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js { render :partial => 'table', :layout => false }
      format.xml  { render :xml => @processes }
    end
  end

  def show
    redirect_to process_journals_path(:wfid => params[:id],:workflow_name => params[:workflow_name])
  end

  def new
    target_type = params[:target_type].camelize
    target_id = params[:target_id]

    target = target_type.constantize.find(target_id)

    if target.workflow_status.code.to_sym == :pending
      flash[:error] = "#{target.name} 正处于流程进行中，无法再发起流程"
      if target.instance_of?(Project)
        redirect_to project_url(target.id)
      else
        redirect_to '/'
      end
      return
    end

    workflow = Workflow.find(params[:workflow_id])

    dept = current_user.business_department
    dept_id = dept ? dept.id : nil

    wfid = RuoteKit.engine.launch(
      workflow.definition,
      :initiator => {
      :user_id => current_user.id,
      :business_department_id =>  dept_id },
      :target => {
      :type => target_type,
      :id => target_id
    },
      :ok => nil,
      :return_to => nil
    )

    # _IMPORTANT_: somehow, the just launched Ruote workflow process
    # _CANNOT_ be obtained by calling RuoteKit.engine.processes(wfid)
    # so cannot rely on calling the :original_tree method of the
    # just launched process.

    # TODO: remove the hack and generalize
    # hack here: :project_status is the workflow status field for Project,
    # 2 is the ID for :pending status
    #target.set_workflow_status(:project_status_id, 2)
    target.on_workflow_launch

    ProcessJournal.create!(
      :workflow_id => workflow.id,
      :wfid => wfid,
      #:original_tree => workflow.tree_json,
      :user_id => current_user.id,
      :comments => '发起流程',
      :workflow_action => '发起流程',
      :owner_type => target_type,
      :owner_id => target_id,
      :ok => true
    )

    w = WorkflowResult.new do |t|
      t.workflow_name = workflow.name
      t.wfid = wfid
      t.target,t.project = WorkflowResult.target_name(target)
      t.result = ''
      t.final_user_id = current_user.id
      t.process_at = Time.now
      t.target_type = target_type
      t.target_id = target.id
      t.ok = 'y'
      t.finish = 'n'
    end
    w.save!

    UserWorkflowResult.check_and_create(w.id, current_user.id)

    i = 0
    until (Ruote::Workitem.for_user(current_user).map{ |r| r.target }.include? target) || (i == 4)
      sleep(0.5)
      i += 1
    end

    # i 大于等于4的时候需要超时提醒
    if i < 4
      flash[:notice] = "#{target.name}的#{workflow.name} 已成功发起！"
    else
      flash[:notice] = "#{target.name}的#{workflow.name} 已成功添加到队列，稍后请刷新！"
    end

    redirect_to :controller => 'workitems', :action => 'index'
  end

  private
  def set_target_workflow_status_to_pending(target)
    @target.workflow_status_id = 2 #pending
  end
  # chect if the target object:
  #   1. exists
  #   2. workflow_launchable by the current logged in user
  def target_valid?(target_type, target_id)
    @target = target_type.camelize.constantize.find(target_id)

    @target_type = target_type
    if !@target
      flash[:error] = "流程对象非法: 请检查对象类型和对象ID"
      return false
    end

    # check if the target object can launched aginst by a workflow process by the current user
    if !@target.workflow_launchable?(current_user)
      flash[:error] = "你没有权限针对该对象发起流程。"
      flash[:error] << " 对象名称: #{@target.name}" if @target.name?
      return false
    end
    true
  end
end
