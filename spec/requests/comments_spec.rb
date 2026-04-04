require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:news_item) { create(:news_item, :published) }

  describe "POST /news/:news_id/comments" do
    context "when logged in" do
      before { login_as(user) }

      it "creates a comment" do
        expect {
          post news_comments_path(news_item), params: { comment: { body: "Great piece!" } }
        }.to change(Comment, :count).by(1)
        expect(response).to redirect_to(news_path(news_item, anchor: "comment-#{Comment.last.id}"))
      end

      it "rejects blank comments" do
        expect {
          post news_comments_path(news_item), params: { comment: { body: "" } }
        }.not_to change(Comment, :count)
        expect(response).to redirect_to(news_path(news_item, anchor: "comments"))
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post news_comments_path(news_item), params: { comment: { body: "Test" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "DELETE /news/:news_id/comments/:id" do
    let!(:comment) { create(:comment, commentable: news_item, user: user) }

    context "as the comment owner" do
      before { login_as(user) }

      it "deletes the comment" do
        expect { delete news_comment_path(news_item, comment) }.to change(Comment, :count).by(-1)
        expect(response).to redirect_to(news_path(news_item, anchor: "comments"))
      end
    end

    context "as a moderator" do
      let(:moderator) { create(:user, :moderator) }
      before { login_as(moderator) }

      it "can delete any comment" do
        expect { delete news_comment_path(news_item, comment) }.to change(Comment, :count).by(-1)
      end
    end

    context "as a different regular user" do
      let(:other_user) { create(:user) }
      before { login_as(other_user) }

      it "is not authorized" do
        delete news_comment_path(news_item, comment)
        expect(response).to redirect_to(news_path(news_item))
      end
    end
  end
end
