require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, :published) }

  describe "POST /articles/:article_id/comments" do
    context "when logged in" do
      before { login_as(user) }

      it "creates a comment" do
        expect {
          post article_comments_path(article), params: { comment: { body: "Great article!" } }
        }.to change(Comment, :count).by(1)
        expect(response).to redirect_to(article_path(article, anchor: "comment-#{Comment.last.id}"))
      end

      it "rejects blank comments" do
        expect {
          post article_comments_path(article), params: { comment: { body: "" } }
        }.not_to change(Comment, :count)
        expect(response).to redirect_to(article_path(article, anchor: "comments"))
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post article_comments_path(article), params: { comment: { body: "Test" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "DELETE /articles/:article_id/comments/:id" do
    let!(:comment) { create(:comment, commentable: article, user: user) }

    context "as the comment owner" do
      before { login_as(user) }

      it "deletes the comment" do
        expect { delete article_comment_path(article, comment) }.to change(Comment, :count).by(-1)
        expect(response).to redirect_to(article_path(article, anchor: "comments"))
      end
    end

    context "as a moderator" do
      let(:moderator) { create(:user, :moderator) }
      before { login_as(moderator) }

      it "can delete any comment" do
        expect { delete article_comment_path(article, comment) }.to change(Comment, :count).by(-1)
      end
    end

    context "as a different regular user" do
      let(:other_user) { create(:user) }
      before { login_as(other_user) }

      it "is not authorized" do
        delete article_comment_path(article, comment)
        expect(response).to redirect_to(article_path(article))
      end
    end
  end
end
