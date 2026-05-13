require "rails_helper"

RSpec.describe KanyadaanApplication, type: :model do
  subject { build(:kanyadaan_application) }

  # ── Validations ─────────────────────────────────────────────────────────────

  describe "validations" do
    it { is_expected.to validate_presence_of(:girl_name) }
    it { is_expected.to validate_presence_of(:parent_name) }
    it { is_expected.to validate_presence_of(:contact) }
    it { is_expected.to validate_presence_of(:location) }

    describe "contact format" do
      it "is valid with a 10-digit Indian mobile number starting with 6-9" do
        subject.contact = "9876543210"
        expect(subject).to be_valid
      end

      it "is invalid with a number starting with 0-5" do
        subject.contact = "5876543210"
        expect(subject).not_to be_valid
        expect(subject.errors[:contact]).to be_present
      end

      it "is invalid with less than 10 digits" do
        subject.contact = "98765432"
        expect(subject).not_to be_valid
      end

      it "is invalid with more than 10 digits" do
        subject.contact = "98765432101"
        expect(subject).not_to be_valid
      end

      it "is invalid with non-numeric characters" do
        subject.contact = "98765abcde"
        expect(subject).not_to be_valid
      end
    end
  end

  # ── Enum ────────────────────────────────────────────────────────────────────

  describe "status enum" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, reviewed: 1, approved: 2, rejected: 3) }

    it "defaults to pending" do
      app = KanyadaanApplication.new
      expect(app.status).to eq("pending")
    end
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  describe ".newest_first" do
    it "orders by created_at descending" do
      old_app = create(:kanyadaan_application, created_at: 2.days.ago)
      new_app = create(:kanyadaan_application, created_at: 1.hour.ago)

      expect(KanyadaanApplication.newest_first).to eq([ new_app, old_app ])
    end
  end
end
