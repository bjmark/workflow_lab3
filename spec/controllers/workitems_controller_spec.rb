# encoding: utf-8
require 'spec_helper'

class W
  attr_accessor :params, :fields

  def [](a)
    fields[a]
  end

  def self.find(id)
    w = new
    w.fields = {'more_info_from_committee_secretary' => 'yes',
      'blade' => { 'helper' => 'WorkflowCreditApprovalHelper' }
    }
    w.params = {'before_edit' => 'custom_fields_for_business_manager'}
    w
  end
end

class P
  def [](id)
    W.find(id)
  end
end

describe WorkitemsController do
  describe "GET edit" do
    specify "Edit" do
      #RuoteKit.stub(storage_participant[params[:id]]
      p = P.new
      RuoteKit.stub(:storage_participant => p)

      RuoteKit.storage_participant[1]['more_info_from_committee_secretary'].should == 'yes'
      get :edit, {:id => 1}
      assigns(:custom_fields).should == { '发送给评审委员会委员' => { 'type' => 'checkbox', 'name' => 'back_to_committee_secretary' } }

      h = assigns(:wk_helper)
      h.instance_variable_get('@new_custom_fields').should == 
        { '发送给评审委员会委员' => { :type => 'checkbox', :name => 'back_to_committee_secretary' } }

      h.class.should == WorkflowCreditApprovalHelper
    end
  end
end
