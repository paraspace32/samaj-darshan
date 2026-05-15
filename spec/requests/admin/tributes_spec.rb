require "rails_helper"

RSpec.describe "Admin::Tributes", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor)      { create(:user, :editor) }
  let(:regular)     { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_tributes_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor" do
      login_as(editor)
      get admin_tributes_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user" do
      login_as(regular)
      get admin_tributes_path
      expect(response).to redirect_to(root_path)
    end

    it "denies unauthenticated access" do
      get admin_tributes_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "CRUD" do
    before { login_as(super_admin) }

    it "renders new form" do
      get new_admin_tribute_path
      expect(response).to have_http_status(:ok)
    end

    it "creates a tribute" do
      expect {
        post admin_tributes_path, params: {
          tribute: {
            name_en: "Test Person",
            description_en: "A great person.",
            image: fixture_file_upload("test_image.jpg", "image/jpeg")
          }
        }
      }.to change(Tribute, :count).by(1)
      expect(response).to redirect_to(admin_tributes_path)
    end

    it "renders edit form" do
      tribute = create(:tribute)
      get edit_admin_tribute_path(tribute)
      expect(response).to have_http_status(:ok)
    end

    it "updates a tribute" do
      tribute = create(:tribute)
      patch admin_tribute_path(tribute), params: {
        tribute: { name_en: "Updated Name" }
      }
      expect(tribute.reload.name_en).to eq("Updated Name")
      expect(response).to redirect_to(admin_tributes_path)
    end

    it "deletes a tribute" do
      tribute = create(:tribute)
      expect {
        delete admin_tribute_path(tribute)
      }.to change(Tribute, :count).by(-1)
    end
  end
end
