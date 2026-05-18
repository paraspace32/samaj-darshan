require "rails_helper"

RSpec.describe "Tributes", type: :request do
  describe "GET /tributes" do
    it "renders the index page" do
      create(:tribute)
      get tributes_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /tributes/:id" do
    it "renders the tribute details" do
      tribute = create(:tribute)
      get tribute_path(tribute)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tribute.display_name)
    end
  end

  describe "POST /tributes/:id/flower" do
    let(:tribute) { create(:tribute) }
    let(:user) { create(:user) }

    it "requires login" do
      post tribute_flower_path(tribute)
      expect(response).to redirect_to(login_path)
    end

    it "creates a flower for logged-in user" do
      login_as(user)
      expect {
        post tribute_flower_path(tribute)
      }.to change(Flower, :count).by(1)
      expect(response).to redirect_to(tribute_path(tribute))
    end

    it "prevents duplicate flowers" do
      login_as(user)
      create(:flower, tribute: tribute, user: user)
      expect {
        post tribute_flower_path(tribute)
      }.not_to change(Flower, :count)
    end
  end

  describe "DELETE /tributes/:id/flower" do
    let(:tribute) { create(:tribute) }
    let(:user) { create(:user) }

    it "removes the user's flower" do
      login_as(user)
      create(:flower, tribute: tribute, user: user)
      expect {
        delete tribute_flower_path(tribute)
      }.to change(Flower, :count).by(-1)
    end
  end
end
