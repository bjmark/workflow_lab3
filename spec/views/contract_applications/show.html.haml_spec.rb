require 'spec_helper'

describe "contract_applications/show" do
  before(:each) do
    @contract_application = assign(:contract_application, stub_model(ContractApplication))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
