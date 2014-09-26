class AgentPrincipalsController < ApplicationController
  def index
    @agent_principals = current_user.agent_relations.includes(:agent)
  end

  def new
    @agent_principal = AgentPrincipal.new
  end

  def create
    @agent_principal = AgentPrincipal.new(params[:agent_principal])
    @agent_principal.principal_id = current_user.id

    respond_to do |format|
      if @agent_principal.save
        format.html { redirect_to(agent_principals_url, :notice => 'Project was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def destroy
    @agent_principal = AgentPrincipal.find(params[:id])
    @agent_principal.destroy

    respond_to do |format|
      format.html { redirect_to(agent_principals_url) }
      format.xml  { head :ok }
    end
  end

end
