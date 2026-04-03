require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /offline" do
    it "renders the offline page" do
      get offline_path
      expect(response).to have_http_status(:ok)
    end
  end
end
