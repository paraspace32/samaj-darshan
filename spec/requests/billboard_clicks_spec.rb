require "rails_helper"

RSpec.describe "BillboardClicks", type: :request do
  describe "GET /click/:id" do
    let(:billboard) { create(:billboard, link_url: "https://example.com/promo") }

    it "increments click count and redirects to link_url" do
      expect {
        get billboard_click_path(billboard)
      }.to change { billboard.reload.clicks_count }.by(1)
      expect(response).to redirect_to("https://example.com/promo")
    end

    it "redirects to root when link_url is blank" do
      billboard.update_column(:link_url, nil)
      get billboard_click_path(billboard)
      expect(response).to redirect_to(root_path)
    end
  end
end
