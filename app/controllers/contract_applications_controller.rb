class ContractApplicationsController < ApplicationController
  # GET /contract_applications
  # GET /contract_applications.xml
  def index
    @contract_applications = ContractApplication.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contract_applications }
    end
  end

  # GET /contract_applications/1
  # GET /contract_applications/1.xml
  def show
    @contract_application = ContractApplication.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @contract_application }
    end
  end

  # GET /contract_applications/new
  # GET /contract_applications/new.xml
  def new
    @contract_application = ContractApplication.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @contract_application }
    end
  end

  # GET /contract_applications/1/edit
  def edit
    @contract_application = ContractApplication.find(params[:id])
  end

  # POST /contract_applications
  # POST /contract_applications.xml
  def create
    project = Project.create!(
      :name => "created by #{params[:contract_application][:name]}", 
      :workflow_status_id => 1,
      :handler_id => current_user.id
    )
    
    financial_term = FinancialTerm.create!(
      :owner_type => 'Project',
      :owner_id => project.id
    )

    @contract_application = ContractApplication.new(params[:contract_application])
    @contract_application.user_id = current_user.id
    @contract_application.workflow_status_id = 1
    @contract_application.financial_term_id = financial_term.id

    respond_to do |format|
      if @contract_application.save
        format.html { redirect_to(@contract_application, :notice => 'Contract application was successfully created.') }
        format.xml  { render :xml => @contract_application, :status => :created, :location => @contract_application }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contract_application.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contract_applications/1
  # PUT /contract_applications/1.xml
  def update
    @contract_application = ContractApplication.find(params[:id])

    respond_to do |format|
      if @contract_application.update_attributes(params[:contract_application])
        format.html { redirect_to(@contract_application, :notice => 'Contract application was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contract_application.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contract_applications/1
  # DELETE /contract_applications/1.xml
  def destroy
    @contract_application = ContractApplication.find(params[:id])
    @contract_application.destroy

    respond_to do |format|
      format.html { redirect_to(contract_applications_url) }
      format.xml  { head :ok }
    end
  end
end
