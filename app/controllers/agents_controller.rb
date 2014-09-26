class AgentsController < ApplicationController
  def index
    @agent_relations = current_user.agent_relations.includes(:agent)
  end

  def new
    @agent_principal = AgentPrincipal.new
  end
end
