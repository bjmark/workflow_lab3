require "spec_helper"

describe WorkflowLogsController do
  describe "routing" do

    it "routes to #index" do
      get("/workflow_logs").should route_to("workflow_logs#index")
    end

    it "routes to #new" do
      get("/workflow_logs/new").should route_to("workflow_logs#new")
    end

    it "routes to #show" do
      get("/workflow_logs/1").should route_to("workflow_logs#show", :id => "1")
    end

    it "routes to #edit" do
      get("/workflow_logs/1/edit").should route_to("workflow_logs#edit", :id => "1")
    end

    it "routes to #create" do
      post("/workflow_logs").should route_to("workflow_logs#create")
    end

    it "routes to #update" do
      put("/workflow_logs/1").should route_to("workflow_logs#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/workflow_logs/1").should route_to("workflow_logs#destroy", :id => "1")
    end

  end
end
