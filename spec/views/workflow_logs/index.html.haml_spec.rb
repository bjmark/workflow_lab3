require 'spec_helper'

describe "workflow_logs/index" do
  before(:each) do
    assign(:workflow_logs, [
      stub_model(WorkflowLog),
      stub_model(WorkflowLog)
    ])
  end

  it "renders a list of workflow_logs" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
