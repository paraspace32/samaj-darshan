require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }

  describe "access control" do
    it "allows only super_admin" do
      login_as(super_admin)
      get admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it "denies editor" do
      login_as(editor)
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/users" do
    before { login_as(super_admin) }

    it "creates a new user" do
      expect {
        post admin_users_path, params: {
          user: { name: "New User", phone: "9111111111", password: "pass1234", password_confirmation: "pass1234", role: "user", status: "active" }
        }
      }.to change(User, :count).by(1)
    end
  end

  describe "PATCH /admin/users/:id/toggle_status" do
    let(:target_user) { create(:user) }
    before { login_as(super_admin) }

    it "blocks an active user" do
      patch toggle_status_admin_user_path(target_user)
      expect(target_user.reload.status).to eq("blocked")
    end

    it "activates a blocked user" do
      target_user.update!(status: :blocked)
      patch toggle_status_admin_user_path(target_user)
      expect(target_user.reload.status).to eq("active")
    end

    it "prevents self-blocking" do
      patch toggle_status_admin_user_path(super_admin)
      expect(response).to redirect_to(admin_users_path)
      expect(super_admin.reload.status).to eq("active")
    end
  end

  describe "GET /admin/users/:id/edit" do
    let(:target_user) { create(:user) }
    before { login_as(super_admin) }

    it "renders the edit form" do
      get edit_admin_user_path(target_user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:target_user) { create(:user) }
    before { login_as(super_admin) }

    it "updates user attributes" do
      patch admin_user_path(target_user), params: { user: { name: "Updated Name" } }
      expect(target_user.reload.name).to eq("Updated Name")
    end

    it "updates without password when password is blank" do
      patch admin_user_path(target_user), params: { user: { name: "No Pass Change", password: "", password_confirmation: "" } }
      expect(target_user.reload.name).to eq("No Pass Change")
    end
  end

  describe "DELETE /admin/users/:id" do
    before { login_as(super_admin) }

    it "deletes a user" do
      target = create(:user)
      expect { delete admin_user_path(target) }.to change(User, :count).by(-1)
    end

    it "prevents self-deletion" do
      expect { delete admin_user_path(super_admin) }.not_to change(User, :count)
    end
  end
end
