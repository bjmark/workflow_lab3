require "spec_helper"

describe DisbursementApplicationsController do
  describe "routing" do

    it "routes to #index" do
      get("/disbursement_applications").should route_to("disbursement_applications#index")
    end

    it "routes to #new" do
      get("/disbursement_applications/new").should route_to("disbursement_applications#new")
    end

    it "routes to #show" do
      get("/disbursement_applications/1").should route_to("disbursement_applications#show", :id => "1")
    end

    it "routes to #edit" do
      get("/disbursement_applications/1/edit").should route_to("disbursement_applications#edit", :id => "1")
    end

    it "routes to #create" do
      post("/disbursement_applications").should route_to("disbursement_applications#create")
    end

    it "routes to #update" do
      put("/disbursement_applications/1").should route_to("disbursement_applications#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/disbursement_applications/1").should route_to("disbursement_applications#destroy", :id => "1")
    end

  end
end
