require 'spec_helper'

describe "contract_applications/index" do
  before(:each) do
    assign(:contract_applications, [
      stub_model(ContractApplication),
      stub_model(ContractApplication)
    ])
  end

  it "renders a list of contract_applications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
