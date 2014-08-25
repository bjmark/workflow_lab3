require 'spec_helper'

describe "contract_applications/edit" do
  before(:each) do
    @contract_application = assign(:contract_application, stub_model(ContractApplication))
  end

  it "renders the edit contract_application form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", contract_application_path(@contract_application), "post" do
    end
  end
end
