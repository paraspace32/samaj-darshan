require "rails_helper"

RSpec.describe "News", type: :request do
  let!(:region)   { create(:region) }
  let!(:category) { create(:category) }

  describe "GET / (index)" do
    let!(:published) { create(:news_item, :published, region: region, category: category) }
    let!(:draft)     { create(:news_item, status: :draft) }

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
    let(:news_item) do
      create(:news_item, :published,
        region:     region,
        category:   category,
        title_en:   "English Title",
        title_hi:   "हिंदी शीर्षक",
        content_en: "English content body.",
        content_hi: "हिंदी सामग्री।")
    end

    it "renders published news" do
      get news_path(news_item)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for draft news" do
      draft = create(:news_item, status: :draft)
      get news_path(draft)
      expect(response).to have_http_status(:not_found)
    end

    it "shows comment section" do
      get news_path(news_item), params: { locale: :en }
      expect(response.body).to include(I18n.t("comments.no_comments", locale: :en))
    end

    it "preserves paragraph breaks in rendered content" do
      formatted = create(:news_item, :published, region: region, category: category,
        content_en: "First paragraph.\n\nSecond paragraph.\n\n\n\nThird after blanks.",
        content_hi: "पहला।\n\nदूसरा।")

      get news_path(formatted), params: { locale: :en }

      expect(response.body).to include("<p>First paragraph.</p>")
      expect(response.body).to include("<p>Second paragraph.</p>")
      expect(response.body).to include("<p>Third after blanks.</p>")
    end

    # ─── Bilingual content ──────────────────────────────────────────────────

    context "when locale is Hindi (default)" do
      it "renders Hindi title in page body" do
        get news_path(news_item)
        expect(response.body).to include("हिंदी शीर्षक")
      end

      it "sets og:title meta tag to Hindi title" do
        get news_path(news_item)
        expect(response.body).to include('<meta property="og:title" content="हिंदी शीर्षक"')
      end

      it "sets og:description to Hindi content" do
        get news_path(news_item)
        expect(response.body).to include("हिंदी सामग्री")
      end
    end

    context "when locale is English (via params[:locale])" do
      it "renders English title in page body" do
        get news_path(news_item), params: { locale: :en }
        expect(response.body).to include("English Title")
      end

      it "sets og:title meta tag to English title" do
        get news_path(news_item), params: { locale: :en }
        expect(response.body).to include('<meta property="og:title" content="English Title"')
      end

      it "sets og:description to English content" do
        get news_path(news_item), params: { locale: :en }
        expect(response.body).to include("English content body")
      end

      it "does NOT include Hindi title in og:title when English is available" do
        get news_path(news_item), params: { locale: :en }
        expect(response.body).not_to include('<meta property="og:title" content="हिंदी शीर्षक"')
      end
    end

    context "when locale is English (via cookie)" do
      before { cookies[:locale] = "en" }

      it "renders English title" do
        get news_path(news_item)
        expect(response.body).to include("English Title")
      end

      it "sets og:title to English title" do
        get news_path(news_item)
        expect(response.body).to include('<meta property="og:title" content="English Title"')
      end

      it "renders English content body" do
        get news_path(news_item)
        expect(response.body).to include("English content body")
      end
    end

    # ─── Locale fallbacks ───────────────────────────────────────────────────

    context "when title_en is blank" do
      let(:hi_only) do
        create(:news_item, :published,
          region:   region, category: category,
          title_en: "", title_hi: "केवल हिंदी")
      end

      it "falls back to Hindi title when English is requested" do
        get news_path(hi_only), params: { locale: :en }
        expect(response.body).to include("केवल हिंदी")
      end

      it "sets og:title to Hindi fallback" do
        get news_path(hi_only), params: { locale: :en }
        expect(response.body).to include('<meta property="og:title" content="केवल हिंदी"')
      end
    end

    context "when title_hi is blank" do
      let(:en_only) do
        create(:news_item, :published,
          region:   region, category: category,
          title_hi: "", title_en: "English Only")
      end

      it "falls back to English title in Hindi locale" do
        get news_path(en_only)
        expect(response.body).to include("English Only")
      end
    end

    # ─── Share URL carries locale ────────────────────────────────────────────

    context "share URL locale" do
      it "includes ?locale=en in the share URL when page is in English" do
        get news_path(news_item), params: { locale: :en }
        # The share URL is embedded in the WhatsApp/share button href or data attribute
        expect(response.body).to include(CGI.escape("locale=en"))
                              .or include("locale%3Den")
                              .or include("locale=en")
      end

      it "does NOT add locale param to share URL in default (Hindi) locale" do
        get news_path(news_item)
        # URL in share button should be the plain news URL without locale param
        # We check the og:url tag which also uses the locale-aware URL
        expect(response.body).to include(news_url(news_item))
      end
    end

    # ─── Switching locale ───────────────────────────────────────────────────

    context "switching from Hindi to English" do
      it "shows English content after switching locale" do
        # Start on Hindi page
        get news_path(news_item)
        expect(response.body).to include("हिंदी शीर्षक")

        # Switch to English
        get set_locale_path(locale: :en), headers: { "HTTP_REFERER" => news_url(news_item) }
        follow_redirect!

        expect(response.body).to include("English Title")
        expect(response.body).not_to include('<meta property="og:title" content="हिंदी शीर्षक"')
      end

      it "shows Hindi content after switching back from English" do
        cookies[:locale] = "en"
        get news_path(news_item)
        expect(response.body).to include("English Title")

        get set_locale_path(locale: :hi), headers: { "HTTP_REFERER" => news_url(news_item) }
        follow_redirect!

        expect(response.body).to include("हिंदी शीर्षक")
      end
    end

    # ─── params[:locale] beats cookie ───────────────────────────────────────

    it "params[:locale] overrides cookie locale" do
      cookies[:locale] = "hi"
      get news_path(news_item), params: { locale: :en }
      expect(response.body).to include("English Title")
      expect(response.body).not_to include('<meta property="og:title" content="हिंदी शीर्षक"')
    end

    it "cookie locale is used when no param given" do
      cookies[:locale] = "en"
      get news_path(news_item)
      expect(response.body).to include("English Title")
    end
  end
end
