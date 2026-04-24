require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "GET /locale/:locale" do
    it "sets locale cookie to hi and redirects back" do
      get set_locale_path(locale: :hi), headers: { "HTTP_REFERER" => root_url }
      expect(response).to redirect_to(root_url)
      expect(response.cookies["locale"]).to eq("hi")
    end

    it "sets locale cookie to en" do
      get set_locale_path(locale: :en), headers: { "HTTP_REFERER" => root_url }
      expect(response.cookies["locale"]).to eq("en")
    end

    it "falls back to default locale for invalid locale" do
      get set_locale_path(locale: :xx), headers: { "HTTP_REFERER" => root_url }
      expect(response.cookies["locale"]).to eq(I18n.default_locale.to_s)
    end

    it "redirects to root_path when no referer" do
      get set_locale_path(locale: :hi)
      expect(response).to redirect_to(root_path)
    end

    it "overwrites an existing locale cookie" do
      cookies[:locale] = "hi"
      get set_locale_path(locale: :en), headers: { "HTTP_REFERER" => root_url }
      expect(response.cookies["locale"]).to eq("en")
    end

    it "redirects back to the referer page after switching" do
      region   = create(:region)
      category = create(:category)
      article  = create(:news_item, :published, region: region, category: category)
      get set_locale_path(locale: :en), headers: { "HTTP_REFERER" => news_url(article) }
      expect(response).to redirect_to(news_url(article))
    end
  end

  describe "locale persistence across requests" do
    it "honours the locale cookie on subsequent requests" do
      # Set cookie to English
      get set_locale_path(locale: :en), headers: { "HTTP_REFERER" => root_url }

      # Follow up request carries the cookie automatically via rack-test
      get root_path
      expect(response).to have_http_status(:ok)
      # I18n.locale should be :en as set by cookie
      expect(I18n.locale).to eq(:en)
    end

    it "uses params[:locale] over cookie locale" do
      cookies[:locale] = "hi"
      get root_path, params: { locale: :en }
      expect(I18n.locale).to eq(:en)
    end

    it "falls back to cookie locale when no param" do
      cookies[:locale] = "en"
      get root_path
      expect(I18n.locale).to eq(:en)
    end

    it "falls back to default locale when neither param nor cookie" do
      get root_path
      expect(I18n.locale).to eq(I18n.default_locale)
    end
  end
end
