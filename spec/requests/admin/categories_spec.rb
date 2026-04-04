require "rails_helper"

RSpec.describe "Admin::Categories", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_categories_path
      expect(response).to have_http_status(:ok)
    end

    it "denies editor" do
      login_as(editor)
      get admin_categories_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/categories" do
    before { login_as(super_admin) }

    it "creates a category" do
      expect {
        post admin_categories_path, params: { category: { name_en: "Sports", name_hi: "खेल", color: "#ff0000" } }
      }.to change(Category, :count).by(1)
    end
  end

  describe "GET /admin/categories/:id/edit" do
    let!(:target_cat) { create(:category) }
    before { login_as(super_admin) }

    it "renders the edit form" do
      get edit_admin_category_path(target_cat)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/categories/:id" do
    let!(:target_cat) { create(:category) }
    before { login_as(super_admin) }

    it "updates the category" do
      patch admin_category_path(target_cat), params: { category: { name_en: "Updated Cat" } }
      expect(response).to redirect_to(admin_categories_path)
      expect(target_cat.reload.name_en).to eq("Updated Cat")
    end

    it "rejects invalid update" do
      patch admin_category_path(target_cat), params: { category: { name_en: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/categories/:id/toggle_active" do
    let!(:target_cat) { create(:category, active: true) }
    before { login_as(super_admin) }

    it "toggles active status" do
      patch toggle_active_admin_category_path(target_cat)
      expect(target_cat.reload.active).to be false
    end
  end

  describe "DELETE /admin/categories/:id" do
    before { login_as(super_admin) }

    it "deletes a category without news" do
      target_cat = create(:category)
      expect { delete admin_category_path(target_cat) }.to change(Category, :count).by(-1)
    end

    it "cannot delete a category with news" do
      target_cat = create(:category)
      create(:news_item, category: target_cat)
      expect { delete admin_category_path(target_cat) }.not_to change(Category, :count)
    end
  end
end
