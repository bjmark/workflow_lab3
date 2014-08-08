require 'spec_helper'

describe "disbursement_applications/new" do
  before(:each) do
    assign(:disbursement_application, stub_model(DisbursementApplication).as_new_record)
  end

  it "renders new disbursement_application form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", disbursement_applications_path, "post" do
    end
  end
end
