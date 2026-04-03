require "rails_helper"

RSpec.describe "Admin::Billboards", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:co_editor) { create(:user, :co_editor) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_billboards_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor" do
      login_as(editor)
      get admin_billboards_path
      expect(response).to have_http_status(:ok)
    end

    it "denies co_editor" do
      login_as(co_editor)
      get admin_billboards_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/billboards" do
    before { login_as(super_admin) }

    it "creates a billboard with an image" do
      expect {
        post admin_billboards_path, params: {
          billboard: {
            title: "New Ad",
            billboard_type: "top_banner",
            image: fixture_file_upload(
              Rails.root.join("spec/fixtures/files/test_image.png"),
              "image/png"
            )
          }
        }
      }.to change(Billboard, :count).by(1)
    end
  end

  describe "GET /admin/billboards/:id/edit" do
    let(:billboard) { create(:billboard) }
    before { login_as(super_admin) }

    it "renders the edit form" do
      get edit_admin_billboard_path(billboard)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/billboards/:id" do
    let(:billboard) { create(:billboard) }
    before { login_as(super_admin) }

    it "updates the billboard" do
      patch admin_billboard_path(billboard), params: { billboard: { title: "Updated Ad" } }
      expect(billboard.reload.title).to eq("Updated Ad")
    end
  end

  describe "DELETE /admin/billboards/:id" do
    let!(:billboard) { create(:billboard) }
    before { login_as(super_admin) }

    it "deletes the billboard" do
      expect { delete admin_billboard_path(billboard) }.to change(Billboard, :count).by(-1)
    end
  end

  describe "PATCH /admin/billboards/:id/toggle_active" do
    let(:billboard) { create(:billboard, active: true) }
    before { login_as(super_admin) }

    it "toggles active status" do
      patch toggle_active_admin_billboard_path(billboard)
      expect(billboard.reload.active).to be false
    end
  end
end
