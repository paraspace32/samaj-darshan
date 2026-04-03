require "rails_helper"

RSpec.describe "Admin::Regions", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_regions_path
      expect(response).to have_http_status(:ok)
    end

    it "denies editor" do
      login_as(editor)
      get admin_regions_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/regions" do
    before { login_as(super_admin) }

    it "creates a region" do
      expect {
        post admin_regions_path, params: { region: { name_en: "Pune", name_hi: "पुणे" } }
      }.to change(Region, :count).by(1)
    end

    it "rejects blank name" do
      post admin_regions_path, params: { region: { name_en: "", name_hi: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/regions/:id/toggle_active" do
    let!(:target_region) { create(:region, active: true) }

    it "toggles active status" do
      login_as(super_admin)
      patch toggle_active_admin_region_path(id: target_region.id)
      expect(response).to redirect_to(admin_regions_path)
      expect(target_region.reload.active).to be false
    end
  end

  describe "DELETE /admin/regions/:id" do
    before { login_as(super_admin) }

    it "deletes a region without articles" do
      target_region = create(:region)
      expect { delete admin_region_path(id: target_region.id) }.to change(Region, :count).by(-1)
    end

    it "cannot delete a region with articles" do
      target_region = create(:region)
      create(:article, region: target_region)
      expect { delete admin_region_path(id: target_region.id) }.not_to change(Region, :count)
    end
  end
end
