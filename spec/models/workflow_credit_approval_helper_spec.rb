#encoding=utf-8
require 'spec_helper'

class W
  attr_accessor :params, :fields

  def [](a)
    fields[a]
  end
end

describe WorkflowCreditApprovalHelper do
  specify do
    wi = W.new
    wi.fields = {'more_info_from_committee_secretary' => 'yes'}
    helper = WorkflowCreditApprovalHelper.new(wi)
    helper.send('custom_fields_for_business_manager')
    helper.custom_fields.should == { '发送给评审委员会委员' => { :type => 'checkbox', :name => 'back_to_committee_secretary' } }
  end
end
