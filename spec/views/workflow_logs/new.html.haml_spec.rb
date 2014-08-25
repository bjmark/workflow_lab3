require 'spec_helper'

describe "workflow_logs/new" do
  before(:each) do
    assign(:workflow_log, stub_model(WorkflowLog).as_new_record)
  end

  it "renders new workflow_log form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", workflow_logs_path, "post" do
    end
  end
end
