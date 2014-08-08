require 'spec_helper'

describe "disbursement_applications/index" do
  before(:each) do
    assign(:disbursement_applications, [
      stub_model(DisbursementApplication),
      stub_model(DisbursementApplication)
    ])
  end

  it "renders a list of disbursement_applications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
