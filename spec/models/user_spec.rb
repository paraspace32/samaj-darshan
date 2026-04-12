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
      it "returns true for super_admin, editor with news section, co_editor" do
        expect(build(:user, :super_admin).can_create_news?).to be true
        expect(build(:user, :editor).can_create_news?).to be true
        expect(build(:user, :co_editor).can_create_news?).to be true
        expect(build(:user, :moderator).can_create_news?).to be false
      end

      it "returns false for editor without news section" do
        expect(build(:user, role: :editor, allowed_sections: %w[jobs]).can_create_news?).to be false
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
      it "returns true for super_admin, editor with news section, moderator" do
        expect(build(:user, :super_admin).can_flag_news?).to be true
        expect(build(:user, :editor).can_flag_news?).to be true
        expect(build(:user, :moderator).can_flag_news?).to be true
        expect(build(:user, :co_editor).can_flag_news?).to be false
      end

      it "returns false for editor without news section" do
        expect(build(:user, role: :editor, allowed_sections: %w[jobs]).can_flag_news?).to be false
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
      it "returns true for super_admin and editor with news section" do
        expect(build(:user, :super_admin).can_review?).to be true
        expect(build(:user, :editor).can_review?).to be true
        expect(build(:user, :co_editor).can_review?).to be false
      end

      it "returns false for editor without news section" do
        expect(build(:user, role: :editor, allowed_sections: %w[jobs]).can_review?).to be false
      end
    end

    describe "#has_section_access?" do
      it "always returns true for super_admin" do
        admin = build(:user, :super_admin)
        User::SECTIONS.each do |section|
          expect(admin.has_section_access?(section)).to be true
        end
      end

      it "returns true for editor with matching section" do
        editor = build(:user, role: :editor, allowed_sections: %w[news webinars])
        expect(editor.has_section_access?("news")).to be true
        expect(editor.has_section_access?("webinars")).to be true
        expect(editor.has_section_access?("jobs")).to be false
      end

      it "returns false for editor with no sections" do
        editor = build(:user, role: :editor, allowed_sections: [])
        expect(editor.has_section_access?("news")).to be false
      end
    end

    describe "section-based permissions for editor" do
      let(:editor_news_only) { build(:user, role: :editor, allowed_sections: %w[news]) }
      let(:editor_jobs_only) { build(:user, role: :editor, allowed_sections: %w[jobs]) }
      let(:editor_all) { build(:user, :editor) }

      it "restricts billboard access by section" do
        expect(build(:user, role: :editor, allowed_sections: %w[billboards]).can_manage_billboards?).to be true
        expect(editor_news_only.can_manage_billboards?).to be false
      end

      it "restricts webinar access by section" do
        expect(build(:user, role: :editor, allowed_sections: %w[webinars]).can_manage_webinars?).to be true
        expect(editor_jobs_only.can_manage_webinars?).to be false
      end

      it "restricts magazine access by section" do
        expect(build(:user, role: :editor, allowed_sections: %w[magazines]).can_manage_magazines?).to be true
        expect(editor_jobs_only.can_manage_magazines?).to be false
      end

      it "restricts education access by section" do
        expect(build(:user, role: :editor, allowed_sections: %w[education]).can_manage_education?).to be true
        expect(editor_news_only.can_manage_education?).to be false
      end

      it "restricts jobs access by section" do
        expect(editor_jobs_only.can_manage_jobs?).to be true
        expect(editor_news_only.can_manage_jobs?).to be false
      end

      it "restricts news publishing by section" do
        expect(editor_news_only.can_publish?).to be true
        expect(editor_jobs_only.can_publish?).to be false
      end

      it "restricts news editing by section" do
        expect(editor_news_only.can_edit_any_news?).to be true
        expect(editor_jobs_only.can_edit_any_news?).to be false
      end
    end

    describe "allowed_sections validation" do
      it "allows valid sections" do
        user = build(:user, role: :editor, allowed_sections: %w[news jobs webinars])
        expect(user).to be_valid
      end

      it "rejects invalid sections" do
        user = build(:user, role: :editor, allowed_sections: %w[news invalid_section])
        expect(user).not_to be_valid
        expect(user.errors[:allowed_sections]).to be_present
      end

      it "allows empty sections" do
        user = build(:user, role: :editor, allowed_sections: [])
        expect(user).to be_valid
      end
    end
  end
end
