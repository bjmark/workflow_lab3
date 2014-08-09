require 'spec_helper'

describe "cash_positions/new" do
  before(:each) do
    assign(:cash_position, stub_model(CashPosition).as_new_record)
  end

  it "renders new cash_position form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", cash_positions_path, "post" do
    end
  end
end
