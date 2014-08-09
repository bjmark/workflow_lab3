require 'spec_helper'

describe "contract_applications/new" do
  before(:each) do
    assign(:contract_application, stub_model(ContractApplication).as_new_record)
  end

  it "renders new contract_application form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", contract_applications_path, "post" do
    end
  end
end
