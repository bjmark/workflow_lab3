class CashPositionsController < ApplicationController
  # GET /cash_positions
  # GET /cash_positions.xml
  def index
    @cash_positions = CashPosition.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cash_positions }
    end
  end

  # GET /cash_positions/1
  # GET /cash_positions/1.xml
  def show
    @cash_position = CashPosition.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cash_position }
    end
  end

  # GET /cash_positions/new
  # GET /cash_positions/new.xml
  def new
    @cash_position = CashPosition.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cash_position }
    end
  end

  # GET /cash_positions/1/edit
  def edit
    @cash_position = CashPosition.find(params[:id])
  end

  # POST /cash_positions
  # POST /cash_positions.xml
  def create
    project = Project.create!(
      :name => "created by #{params[:cash_position][:name]}", 
      :workflow_status_id => 1,
      :handler_id => current_user.id
    )
    @cash_position = CashPosition.new(params[:cash_position])
    @cash_position.project_id = project.id
    @cash_position.workflow_status_id = 1

    respond_to do |format|
      if @cash_position.save
        format.html { redirect_to(@cash_position, :notice => 'Cash position was successfully created.') }
        format.xml  { render :xml => @cash_position, :status => :created, :location => @cash_position }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cash_position.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cash_positions/1
  # PUT /cash_positions/1.xml
  def update
    @cash_position = CashPosition.find(params[:id])

    respond_to do |format|
      if @cash_position.update_attributes(params[:cash_position])
        format.html { redirect_to(@cash_position, :notice => 'Cash position was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cash_position.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cash_positions/1
  # DELETE /cash_positions/1.xml
  def destroy
    @cash_position = CashPosition.find(params[:id])
    @cash_position.destroy

    respond_to do |format|
      format.html { redirect_to(cash_positions_url) }
      format.xml  { head :ok }
    end
  end
end
