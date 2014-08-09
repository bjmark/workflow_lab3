require "spec_helper"

describe CashPositionsController do
  describe "routing" do

    it "routes to #index" do
      get("/cash_positions").should route_to("cash_positions#index")
    end

    it "routes to #new" do
      get("/cash_positions/new").should route_to("cash_positions#new")
    end

    it "routes to #show" do
      get("/cash_positions/1").should route_to("cash_positions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/cash_positions/1/edit").should route_to("cash_positions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/cash_positions").should route_to("cash_positions#create")
    end

    it "routes to #update" do
      put("/cash_positions/1").should route_to("cash_positions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/cash_positions/1").should route_to("cash_positions#destroy", :id => "1")
    end

  end
end
