class WorkflowResultsController < ApplicationController
  # GET /workflow_results
  # GET /workflow_results.xml
  def index
    @workflow_results = current_user.workflow_results.project_like(params[:search]).where(:finish => 'y').
      includes(:final_user).order('id desc')
  end
end
