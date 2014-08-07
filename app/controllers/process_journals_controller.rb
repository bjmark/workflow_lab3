# -*-_ encoding: utf-8 -*-
class ProcessJournalsController < ApplicationController
  # index by workflow process id (:wfid column in the table)
  def index
    wfid = params[:wfid]
    @workflow_name = params[:workflow_name]
    @process_journals = ProcessJournal.where(:wfid => wfid).all

    if !@process_journals.blank?
      @target = @process_journals.first.owner
    end
  end

  def processed
    redirect_to workflow_results_path
  end

  def get_comments
    render :partial => '/process_journals/table', :locals => {:process_journals => ProcessJournal.for_workitem(params[:wfid])}
  end
end
