class DisbursementApplicationsController < ApplicationController
  # GET /disbursement_applications
  # GET /disbursement_applications.xml
  def index
    @disbursement_applications = DisbursementApplication.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @disbursement_applications }
    end
  end

  # GET /disbursement_applications/1
  # GET /disbursement_applications/1.xml
  def show
    @disbursement_application = DisbursementApplication.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @disbursement_application }
    end
  end

  # GET /disbursement_applications/new
  # GET /disbursement_applications/new.xml
  def new
    @disbursement_application = DisbursementApplication.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @disbursement_application }
    end
  end

  # GET /disbursement_applications/1/edit
  def edit
    @disbursement_application = DisbursementApplication.find(params[:id])
  end

  # POST /disbursement_applications
  # POST /disbursement_applications.xml
  def create
    @disbursement_application = DisbursementApplication.new(params[:disbursement_application])
    @disbursement_application.workflow_status_id = 1

    respond_to do |format|
      if @disbursement_application.save
        format.html { redirect_to(@disbursement_application, :notice => 'Disbursement application was successfully created.') }
        format.xml  { render :xml => @disbursement_application, :status => :created, :location => @disbursement_application }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @disbursement_application.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /disbursement_applications/1
  # PUT /disbursement_applications/1.xml
  def update
    @disbursement_application = DisbursementApplication.find(params[:id])

    respond_to do |format|
      if @disbursement_application.update_attributes(params[:disbursement_application])
        format.html { redirect_to(@disbursement_application, :notice => 'Disbursement application was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @disbursement_application.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /disbursement_applications/1
  # DELETE /disbursement_applications/1.xml
  def destroy
    @disbursement_application = DisbursementApplication.find(params[:id])
    @disbursement_application.destroy

    respond_to do |format|
      format.html { redirect_to(disbursement_applications_url) }
      format.xml  { head :ok }
    end
  end
end
