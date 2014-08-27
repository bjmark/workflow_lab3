# encoding: utf-8
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

    @workitem.on_participant_entry(current_user)
    if @workitem.target.errors.any?
      flash[:alert] = "#{@workitem.target.errors.full_messages.join("\n")}"
    end
  end

  def update
    @workitem = RuoteKit.storage_participant[params[:id]]

    # workitem _CANNOT_ be located, meaning it has been handled by somebody else
    # and it not long available in your queue
    if !@workitem
      flash[:alert] = "无法提交。该事项可能已提交，或已由同岗位的其他用户处理提交。"
      redirect_to :action => :index
      return
    end

    if !@workitem.belongs_to?(current_user)
      flash[:alert] = "该事项不在当前用户队列，不能提交。ID: #{workitem.fei.sid}"
      redirect_to :action => :index
      return
    end

    begin
      op_name = params[:workitem][:submit]
      case op_name.to_sym
      when :proceed
        fill_in_workitem_fields
        wf_action = '提交'
        @workitem.on_participant_exit(current_user)
      when :return
        fill_in_workitem_fields
        wf_action = '退回'
        @workitem.on_participant_exit(current_user)
        @workitem.command = [ 'jump', @workitem.prev_tag ]
      else
        raise "Operation Not Supported Yet!"
      end

      # 用于取消overview中某个字段的修改权限
      ProcessJournal.create!([{
        :workflow_id => @workitem.workflow_id,
        :wfid => @workitem.wfid,
        :current_tree => @workitem.process.current_tree,
        :user_id => current_user.id,
        :as_role_id => @workitem.as_role.try(:id),
        :comments => params[:workitem][:comments],
        :workflow_action => wf_action,
        :owner_type => @workitem.target.class,
        :owner_id => @workitem.target.id
      }])

      wf_result = WorkflowResult.where(:wfid => @workitem.wfid).first
      if wf_result
        wf_result.process_at = Time.now
        wf_result.final_user_id = current_user.id
        wf_result.save!
      end

      # this needs to happen at last, due to the async nature
      # of Ruote engine which is running in a separate process
      # @workitem.process will be nil after the .proceed call
      RuoteKit.storage_participant.proceed(@workitem)

      flash[:notice] = "流程流转成功。"
      redirect_to :action => :index
    rescue Exception => e
      flash[:error] = "流程处理出错: #{e.message}"
      render :action => :edit
    end
  end

  def workflow_diagram
    @workitem = RuoteKit.storage_participant[params[:id]]
    render :partial => "fluo", :layout => false
  end

  private
  def fill_in_workitem_fields
    Array(params[:workitem][:fields]).each do |field_name, value|
      @workitem.fields[field_name] = value
    end
  end
end
