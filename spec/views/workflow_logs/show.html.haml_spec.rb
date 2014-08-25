require 'spec_helper'

describe "workflow_logs/show" do
  before(:each) do
    @workflow_log = assign(:workflow_log, stub_model(WorkflowLog))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
