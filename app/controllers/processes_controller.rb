# encoding: utf-8
# This is for list processes that contains workitems that the current user
# has worked on.
# For application wide Ruote::ProcessStatus related resource controller,
# use the build in Rack URL: http://host/_ruote
class ProcessesController < ApplicationController
  # load_and_authorize_resource

  def index
    wfids = []
    if current_user.admin?
      wfids = WorkflowResult.where(:finished => false).map(&:wfid)
    else
      wfids = ProcessJournal.wfids_for_user(current_user)
    end

    @processes = []
    wfids.each do |wfid|
      p = RuoteKit.engine.process(wfid)
      @processes << p if p
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    redirect_to process_journals_path(
      :wfid => params[:id], :workflow_name => params[:workflow_name])
  end

  # launch a Workflow process
  def new
    target_type = params[:target_type].camelize
    target_id = params[:target_id]

    target = target_type.constantize.find(target_id)
    workflow = Workflow.find(params[:workflow_id])
    @process = WorkflowProcess.new(workflow, target, current_user)

    if @process.launch
      redirect_to workitems_path, :notice => "#{@process.message}"
    else
      render '_unmet_conditions', :locals => { :target => target }, :layout => '/layouts/application'
      # if target.instance_of?(Project)
      #   redirect_to project_url(target.id), :alert => "#{@process.message}"
      # else
      #   redirect_to '/', :alert => "#{@process.message}"
      # end
    end
  end
end
