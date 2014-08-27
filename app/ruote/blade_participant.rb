# encoding: utf-8
# TODO maynot need this at all
require 'ruote'
class BladeParticipant < Ruote::Participant
  private
  def handle_invalid_target
    workflow = Workflow.where(:id => workitem.fields["workflow_id"]).first
    Rails.logger.error "Workflow Completion Error: Invalid target"
    Rails.logger.error "  #{workitem.fields["target_type"]} - #{workitem.fields["target_id"]}"
    Rails.logger.error "  #{workflow.try(:name)} - WFID:#{wi.wfid}"

    # _CANNOT_ reply here. We want reply to happen when user press
    # a buuton on the webpage, not automatically.
    # reply
  end
end
