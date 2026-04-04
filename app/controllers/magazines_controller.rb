class MagazinesController < ApplicationController
  def index
    @magazines = Magazine.visible.includes(cover_image_attachment: :blob)
  end

  def show
    @magazine = Magazine.published.find(params[:id])
    @articles = @magazine.magazine_articles.ordered.includes(:author, cover_image_attachment: :blob)
  end
end
