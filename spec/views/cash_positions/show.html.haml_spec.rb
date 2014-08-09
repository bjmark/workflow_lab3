require 'spec_helper'

describe "cash_positions/show" do
  before(:each) do
    @cash_position = assign(:cash_position, stub_model(CashPosition))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
