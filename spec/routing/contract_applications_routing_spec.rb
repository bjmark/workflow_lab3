require "spec_helper"

describe ContractApplicationsController do
  describe "routing" do

    it "routes to #index" do
      get("/contract_applications").should route_to("contract_applications#index")
    end

    it "routes to #new" do
      get("/contract_applications/new").should route_to("contract_applications#new")
    end

    it "routes to #show" do
      get("/contract_applications/1").should route_to("contract_applications#show", :id => "1")
    end

    it "routes to #edit" do
      get("/contract_applications/1/edit").should route_to("contract_applications#edit", :id => "1")
    end

    it "routes to #create" do
      post("/contract_applications").should route_to("contract_applications#create")
    end

    it "routes to #update" do
      put("/contract_applications/1").should route_to("contract_applications#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/contract_applications/1").should route_to("contract_applications#destroy", :id => "1")
    end

  end
end
