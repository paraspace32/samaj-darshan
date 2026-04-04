module Admin
  class MagazineArticlesController < BaseController
    before_action :set_magazine
    before_action :set_article, only: [:edit, :update, :destroy]

    def new
      @article = @magazine.magazine_articles.build(position: next_position)
    end

    def create
      @article = @magazine.magazine_articles.build(article_params)
      @article.author = current_user
      if @article.save
        redirect_to admin_magazine_path(@magazine), notice: "Article added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to admin_magazine_path(@magazine), notice: "Article updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_magazine_path(@magazine), notice: "Article removed."
    end

    private

    def set_magazine
      @magazine = Magazine.find(params[:magazine_id])
    end

    def set_article
      @article = @magazine.magazine_articles.find(params[:id])
    end

    def next_position
      (@magazine.magazine_articles.maximum(:position) || -1) + 1
    end

    def article_params
      params.require(:magazine_article).permit(
        :title_en, :title_hi, :content_en, :content_hi,
        :position, :cover_image
      )
    end
  end
end
