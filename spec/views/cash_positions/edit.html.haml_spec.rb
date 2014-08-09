require 'spec_helper'

describe "cash_positions/edit" do
  before(:each) do
    @cash_position = assign(:cash_position, stub_model(CashPosition))
  end

  it "renders the edit cash_position form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", cash_position_path(@cash_position), "post" do
    end
  end
end
