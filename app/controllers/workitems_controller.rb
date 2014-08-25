# -*- encoding: utf-8 -*-
# Ruote::Worktiem
class WorkitemsController < ApplicationController
  #load_and_authorize_resource
  def index
    @workitems = Ruote::Workitem.for_user(current_user)
  end

  def show
    @workitem = RuoteKit.storage_participant[params[:id]]
  end

  def edit
    @workitem = RuoteKit.storage_participant[params[:id]]

    wk_helper.before_edit
    @submit_values = wk_helper.merge_submit.keys
    @message = @workitem.fields['message'] || []
    @form = wk_helper.form
    @view = wk_helper.view
  end

  def update
    @workitem = RuoteKit.storage_participant[params[:id]]

    # workitem _CANNOT_ be located, meaning it has been handled by somebody else
    # and it not long available in your queue
    if !@workitem
      flash[:error] = "无法提交。该事项可能已处理，或已由同岗位/角色的其他用户处理提交。"
      redirect_to :action => :index
      return
    end

    if !@workitem.belongs_to?(current_user)
      flash[:error] = "该事项不在当前用户队列，不能提交。ID: #{workitem.fei.sid}"
      redirect_to :action => :index
      return
    end

    op_name = params[:workitem][:submit]
    error = wk_helper.validate(op_name)
    if !error.empty?
      flash[:error] = error
      redirect_to :action => :edit 
      return
    end

    @comments = params[:workitem][:comments] 
    wk_helper.before_proceed(op_name)
    wk_helper.exec_submit(op_name)

    begin
      RuoteKit.storage_participant.proceed(@workitem)
    rescue
      flash[:error] = "该事项可能已处理，或已由同岗位/角色的其他用户处理提交。"
      redirect_to :action => :index
      return
    end

    ProcessJournal.create!([{
      :wfid => @workitem.wfid,
      #:current_tree => RuoteKit.engine.process(workitem.wfid).current_tree,
      :user_id => current_user.id,
      :as_role_id => Role.find_by_code(@workitem.participant_name).id,
      :comments => @comments, 
      :workflow_action => op_name,
      :owner_type => @workitem.fields["target"]["type"].camelize,
      :owner_id => @workitem.fields["target"]["id"],
      :ok => @workitem.fields["ok"] }
    ])

    w = WorkflowResult.where(:wfid => @workitem.wfid).first
    unless w.blank?
      w.process_at = Time.now
      w.final_user_id = current_user.id
      w.save!
    end

    UserWorkflowResult.check_and_create(w.id, current_user.id)

    redirect_to :action => :index
  end
  
  def wk_helper
    @wk_helper if  @wk_helper
    
    class_name = @workitem.fields['blade']['helper']
    if class_name
      @wk_helper = Object.const_get(class_name).new(@workitem, self, current_user)
    else
      @wk_helper = WorkflowHelper.new(@workitem, self, current_user)
    end
  end
end
