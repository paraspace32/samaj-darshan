require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:news).with_foreign_key(:author_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_uniqueness_of(:phone).case_insensitive }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:email).allow_blank }
    it { is_expected.to have_secure_password }

    it "normalizes blank email to nil" do
      user = build(:user, email: "")
      user.valid?
      expect(user.email).to be_nil
    end

    it "allows multiple users with blank email" do
      create(:user, email: "")
      user2 = build(:user, email: "")
      expect(user2).to be_valid
    end

    it "allows valid Indian phone numbers" do
      %w[9876543210 6000000000 7123456789 8999999999].each do |phone|
        subject.phone = phone
        subject.valid?
        expect(subject.errors[:phone]).to be_empty
      end
    end

    it "rejects invalid phone numbers" do
      %w[0000000000 5123456789 123 12345678901 abcdefghij].each do |phone|
        subject.phone = phone
        subject.valid?
        expect(subject.errors[:phone]).to be_present
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(super_admin: 0, editor: 1, co_editor: 2, moderator: 3, user: 4) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, blocked: 1).with_prefix(:account) }
  end

  describe "scopes" do
    it ".by_role returns users with specified role" do
      admin = create(:user, :super_admin)
      editor = create(:user, :editor)
      expect(User.by_role(:super_admin)).to include(admin)
      expect(User.by_role(:super_admin)).not_to include(editor)
    end

    it ".active_users returns non-blocked users" do
      active = create(:user)
      blocked = create(:user, :blocked)
      expect(User.active_users).to include(active)
      expect(User.active_users).not_to include(blocked)
    end
  end

  describe "permission methods" do
    describe "#admin_panel_access?" do
      it "returns true for super_admin, editor, co_editor, moderator" do
        %i[super_admin editor co_editor moderator].each do |role|
          expect(build(:user, role: role).admin_panel_access?).to be true
        end
      end

      it "returns false for regular users" do
        expect(build(:user, role: :user).admin_panel_access?).to be false
      end
    end

    describe "#can_manage_users?" do
      it "returns true only for super_admin" do
        expect(build(:user, :super_admin).can_manage_users?).to be true
        expect(build(:user, :editor).can_manage_users?).to be false
      end
    end

    describe "#can_manage_billboards?" do
      it "returns true for super_admin and editor" do
        expect(build(:user, :super_admin).can_manage_billboards?).to be true
        expect(build(:user, :editor).can_manage_billboards?).to be true
        expect(build(:user, :co_editor).can_manage_billboards?).to be false
      end
    end

    describe "#can_create_news?" do
      it "returns true for super_admin, editor, co_editor" do
        %i[super_admin editor co_editor].each do |role|
          expect(build(:user, role: role).can_create_news?).to be true
        end
        expect(build(:user, :moderator).can_create_news?).to be false
      end
    end

    describe "#can_edit_news?" do
      let(:author) { create(:user, :co_editor) }
      let(:news_item) { create(:news_item, author: author) }

      it "returns true for the news co_editor author" do
        expect(author.can_edit_news?(news_item)).to be true
      end

      it "returns false for a different co_editor" do
        other = create(:user, :co_editor)
        expect(other.can_edit_news?(news_item)).to be false
      end

      it "returns true for super_admin regardless" do
        expect(build(:user, :super_admin).can_edit_news?(news_item)).to be true
      end
    end

    describe "#can_publish?" do
      it "returns true for super_admin and editor" do
        expect(build(:user, :super_admin).can_publish?).to be true
        expect(build(:user, :editor).can_publish?).to be true
        expect(build(:user, :co_editor).can_publish?).to be false
      end
    end

    describe "#can_delete_news?" do
      it "returns true only for super_admin" do
        expect(build(:user, :super_admin).can_delete_news?).to be true
        expect(build(:user, :editor).can_delete_news?).to be false
      end
    end

    describe "#can_flag_news?" do
      it "returns true for super_admin, editor, moderator" do
        %i[super_admin editor moderator].each do |role|
          expect(build(:user, role: role).can_flag_news?).to be true
        end
        expect(build(:user, :co_editor).can_flag_news?).to be false
      end
    end

    describe "#can_manage_regions?" do
      it "returns true only for super_admin" do
        expect(build(:user, :super_admin).can_manage_regions?).to be true
        expect(build(:user, :editor).can_manage_regions?).to be false
      end
    end

    describe "#can_manage_categories?" do
      it "returns true only for super_admin" do
        expect(build(:user, :super_admin).can_manage_categories?).to be true
        expect(build(:user, :editor).can_manage_categories?).to be false
      end
    end

    describe "#can_manage_live_streams?" do
      it "returns true for super_admin and editor" do
        expect(build(:user, :super_admin).can_manage_live_streams?).to be true
        expect(build(:user, :editor).can_manage_live_streams?).to be true
        expect(build(:user, :co_editor).can_manage_live_streams?).to be false
      end
    end

    describe "#can_edit_any_news?" do
      it "returns true for super_admin and editor" do
        expect(build(:user, :super_admin).can_edit_any_news?).to be true
        expect(build(:user, :editor).can_edit_any_news?).to be true
        expect(build(:user, :co_editor).can_edit_any_news?).to be false
      end
    end

    describe "#can_review?" do
      it "returns true for super_admin and editor" do
        expect(build(:user, :super_admin).can_review?).to be true
        expect(build(:user, :editor).can_review?).to be true
        expect(build(:user, :co_editor).can_review?).to be false
      end
    end
  end
end
