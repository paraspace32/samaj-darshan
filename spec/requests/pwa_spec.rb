require "rails_helper"

RSpec.describe "PWA", type: :request do
  describe "GET /manifest" do
    it "returns a valid JSON manifest" do
      get pwa_manifest_path(format: :json)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["id"]).to eq("/")
      expect(json["name"]).to be_present
      expect(json["short_name"]).to be_present
      expect(json["start_url"]).to eq("/")
      expect(json["scope"]).to eq("/")
      expect(json["icons"]).to be_an(Array)
      expect(json["icons"].size).to eq(4)
      expect(json["display"]).to eq("standalone")
      expect(json["theme_color"]).to eq("#ea580c")
    end
  end

  describe "GET /service-worker" do
    it "returns JavaScript content" do
      get pwa_service_worker_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/javascript")
      expect(response.headers["Service-Worker-Allowed"]).to eq("/")
      expect(response.body).to include("CACHE_VERSION")
      expect(response.body).to include("addEventListener")
      expect(response.body).to include("clients.claim")
    end
  end
end
