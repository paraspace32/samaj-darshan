class CommentsController < ApplicationController
  before_action :require_login
  before_action :require_active_account
  before_action :set_article

  def create
    @comment = @article.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to article_path(@article, anchor: "comment-#{@comment.id}"), notice: t("comments.posted")
    else
      redirect_to article_path(@article, anchor: "comments"), alert: @comment.errors.full_messages.first
    end
  end

  def destroy
    @comment = @article.comments.find(params[:id])

    unless @comment.user_id == current_user.id || current_user.super_admin? || current_user.editor? || current_user.moderator?
      redirect_to article_path(@article), alert: t("flash.not_authorized") and return
    end

    @comment.destroy
    redirect_to article_path(@article, anchor: "comments"), notice: t("comments.deleted")
  end

  private

  def set_article
    @article = Article.published.find(params[:article_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
