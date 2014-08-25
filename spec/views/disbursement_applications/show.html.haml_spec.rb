require 'spec_helper'

describe "disbursement_applications/show" do
  before(:each) do
    @disbursement_application = assign(:disbursement_application, stub_model(DisbursementApplication))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
