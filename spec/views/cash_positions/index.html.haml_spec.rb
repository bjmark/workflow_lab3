require 'spec_helper'

describe "cash_positions/index" do
  before(:each) do
    assign(:cash_positions, [
      stub_model(CashPosition),
      stub_model(CashPosition)
    ])
  end

  it "renders a list of cash_positions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
