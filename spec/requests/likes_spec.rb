require "rails_helper"

RSpec.describe "Likes", type: :request do
  let(:user) { create(:user) }
  let(:news_item) { create(:news_item, :published) }

  describe "POST /news/:news_id/like/toggle" do
    context "when logged in" do
      before { login_as(user) }

      it "creates a like" do
        expect {
          post toggle_news_like_path(news_item)
        }.to change(Like, :count).by(1)
        expect(response).to redirect_to(news_path(news_item, anchor: "like-section"))
      end

      it "removes an existing like (toggle off)" do
        create(:like, likeable: news_item, user: user)
        expect {
          post toggle_news_like_path(news_item)
        }.to change(Like, :count).by(-1)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post toggle_news_like_path(news_item)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
