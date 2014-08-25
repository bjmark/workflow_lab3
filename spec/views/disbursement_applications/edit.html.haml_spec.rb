require 'spec_helper'

describe "disbursement_applications/edit" do
  before(:each) do
    @disbursement_application = assign(:disbursement_application, stub_model(DisbursementApplication))
  end

  it "renders the edit disbursement_application form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", disbursement_application_path(@disbursement_application), "post" do
    end
  end
end
