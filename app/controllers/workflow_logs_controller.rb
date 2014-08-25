class WorkflowLogsController < ApplicationController
  # GET /workflow_logs
  # GET /workflow_logs.xml
  def index
    @workflow_logs = WorkflowLog.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @workflow_logs }
    end
  end

  # GET /workflow_logs/1
  # GET /workflow_logs/1.xml
  def show
    @workflow_log = WorkflowLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @workflow_log }
    end
  end

  # GET /workflow_logs/new
  # GET /workflow_logs/new.xml
  def new
    @workflow_log = WorkflowLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @workflow_log }
    end
  end

  # GET /workflow_logs/1/edit
  def edit
    @workflow_log = WorkflowLog.find(params[:id])
  end

  # POST /workflow_logs
  # POST /workflow_logs.xml
  def create
    @workflow_log = WorkflowLog.new(params[:workflow_log])

    respond_to do |format|
      if @workflow_log.save
        format.html { redirect_to(@workflow_log, :notice => 'Workflow log was successfully created.') }
        format.xml  { render :xml => @workflow_log, :status => :created, :location => @workflow_log }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @workflow_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /workflow_logs/1
  # PUT /workflow_logs/1.xml
  def update
    @workflow_log = WorkflowLog.find(params[:id])

    respond_to do |format|
      if @workflow_log.update_attributes(params[:workflow_log])
        format.html { redirect_to(@workflow_log, :notice => 'Workflow log was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @workflow_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /workflow_logs/1
  # DELETE /workflow_logs/1.xml
  def destroy
    @workflow_log = WorkflowLog.find(params[:id])
    @workflow_log.destroy

    respond_to do |format|
      format.html { redirect_to(workflow_logs_url) }
      format.xml  { head :ok }
    end
  end

  def delete_all
    WorkflowLog.delete_all
    redirect_to '/workflow_logs'
  end
end
