class CommentsController < ApplicationController
  before_action :require_login
  before_action :require_active_account
  before_action :set_commentable

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to helpers.commentable_path(@commentable, anchor: "comment-#{@comment.id}"), notice: t("comments.posted")
    else
      redirect_to helpers.commentable_path(@commentable, anchor: "comments"), alert: @comment.errors.full_messages.first
    end
  end

  def destroy
    @comment = @commentable.comments.find(params[:id])

    unless @comment.user_id == current_user.id || current_user.super_admin? || current_user.editor? || current_user.moderator?
      redirect_to helpers.commentable_path(@commentable), alert: t("flash.not_authorized") and return
    end

    @comment.destroy
    redirect_to helpers.commentable_path(@commentable, anchor: "comments"), notice: t("comments.deleted")
  end

  private

  def set_commentable
    if params[:news_id]
      @commentable = News.published.find(params[:news_id])
    elsif params[:education_id]
      @commentable = EducationPost.published.find(params[:education_id])
    elsif params[:job_id]
      @commentable = JobPost.published.find(params[:job_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
