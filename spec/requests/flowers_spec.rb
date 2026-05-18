require "rails_helper"

RSpec.describe "Flowers", type: :request do
  let(:user) { create(:user) }
  let(:tribute) { create(:tribute) }

  describe "POST /tributes/:tribute_id/flower" do
    it "requires login" do
      post tribute_flower_path(tribute)
      expect(response).to redirect_to(login_path)
    end

    it "creates a flower for the tribute" do
      login_as(user)
      expect {
        post tribute_flower_path(tribute)
      }.to change { tribute.reload.flowers_count }.by(1)
      expect(response).to redirect_to(tribute_path(tribute))
    end

    it "prevents duplicate flowers from same user" do
      create(:flower, tribute: tribute, user: user)
      login_as(user)
      expect {
        post tribute_flower_path(tribute)
      }.not_to change(Flower, :count)
      expect(response).to redirect_to(tribute_path(tribute))
    end
  end

  describe "DELETE /tributes/:tribute_id/flower" do
    it "removes the user's flower" do
      create(:flower, tribute: tribute, user: user)
      login_as(user)
      expect {
        delete tribute_flower_path(tribute)
      }.to change { tribute.reload.flowers_count }.by(-1)
      expect(response).to redirect_to(tribute_path(tribute))
    end

    it "handles missing flower gracefully" do
      login_as(user)
      delete tribute_flower_path(tribute)
      expect(response).to redirect_to(tribute_path(tribute))
    end
  end
end
