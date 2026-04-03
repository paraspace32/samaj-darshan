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
  end
end
