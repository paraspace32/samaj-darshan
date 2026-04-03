require "rails_helper"

RSpec.describe "Likes", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, :published) }

  describe "POST /articles/:article_id/like/toggle" do
    context "when logged in" do
      before { login_as(user) }

      it "creates a like" do
        expect {
          post toggle_article_like_path(article)
        }.to change(Like, :count).by(1)
        expect(response).to redirect_to(article_path(article, anchor: "like-section"))
      end

      it "removes an existing like (toggle off)" do
        create(:like, likeable: article, user: user)
        expect {
          post toggle_article_like_path(article)
        }.to change(Like, :count).by(-1)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post toggle_article_like_path(article)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
