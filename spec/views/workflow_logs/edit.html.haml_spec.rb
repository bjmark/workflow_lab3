require 'spec_helper'

describe "workflow_logs/edit" do
  before(:each) do
    @workflow_log = assign(:workflow_log, stub_model(WorkflowLog))
  end

  it "renders the edit workflow_log form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", workflow_log_path(@workflow_log), "post" do
    end
  end
end
