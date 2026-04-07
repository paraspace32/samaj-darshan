require "rails_helper"

RSpec.describe "News", type: :request do
  let!(:region) { create(:region) }
  let!(:category) { create(:category) }

  describe "GET / (index)" do
    let!(:published) { create(:news_item, :published, region: region, category: category) }
    let!(:draft) { create(:news_item, status: :draft) }

    it "renders successfully" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "shows published news only" do
      get root_path
      expect(response.body).to include(published.display_title)
      expect(response.body).not_to include(draft.title_en)
    end

    it "filters by region" do
      create(:news_item, :published)
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

  describe "GET /news/:id (show)" do
    let(:news_item) { create(:news_item, :published, region: region, category: category) }

    it "renders published news" do
      get news_path(news_item)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(news_item.display_title)
    end

    it "returns 404 for draft news" do
      draft = create(:news_item, status: :draft)
      get news_path(draft)
      expect(response).to have_http_status(:not_found)
    end

    it "shows like and comment sections" do
      get news_path(news_item), params: { locale: :en }
      expect(response.body).to include("Comments")
    end

    it "preserves paragraph breaks and blank lines in rendered content" do
      formatted_news = create(:news_item, :published, region: region, category: category,
        content_en: "First paragraph.\n\nSecond paragraph.\n\n\n\nThird after blanks.",
        content_hi: "पहला।\n\nदूसरा।")

      get news_path(formatted_news), params: { locale: :en }

      expect(response.body).to include("<p>First paragraph.</p>")
      expect(response.body).to include("<p>Second paragraph.</p>")
      expect(response.body).to include("<p>Third after blanks.</p>")
    end
  end
end
