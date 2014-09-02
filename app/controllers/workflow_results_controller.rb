class WorkflowResultsController < ApplicationController
  # GET /workflow_results
  # GET /workflow_results.xml
  def index
    #@workflow_results = current_user.workflow_results.project_like(params[:search]).where(:finish => 'y').
    #  includes(:final_user).order('id desc')

    @workflow_results = WorkflowResult.scoped

    if !current_user.admin?
      @workflow_results = WorkflowResult.for_user(current_user)
    end

    @workflow_results = @workflow_results.
      where(:finished => true).includes(:final_user).
      order('id desc')
  end
end
