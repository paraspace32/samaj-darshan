require "rails_helper"

RSpec.describe "Articles", type: :request do
  let!(:region) { create(:region) }
  let!(:category) { create(:category) }

  describe "GET / (index)" do
    let!(:published) { create(:article, :published, region: region, category: category) }
    let!(:draft) { create(:article, status: :draft) }

    it "renders successfully" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "shows published articles only" do
      get root_path
      expect(response.body).to include(published.display_title)
      expect(response.body).not_to include(draft.title_en)
    end

    it "filters by region" do
      other_article = create(:article, :published)
      get region_feed_path(slug: region.slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(published.display_title)
    end

    it "filters by category" do
      get category_feed_path(slug: category.slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(published.display_title)
    end
  end

  describe "GET /articles/:id (show)" do
    let(:article) { create(:article, :published, region: region, category: category) }

    it "renders a published article" do
      get article_path(article)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(article.display_title)
    end

    it "returns 404 for draft articles" do
      draft = create(:article, status: :draft)
      get article_path(draft)
      expect(response).to have_http_status(:not_found)
    end

    it "shows like and comment sections" do
      get article_path(article), params: { locale: :en }
      expect(response.body).to include("Comments")
    end
  end
end
