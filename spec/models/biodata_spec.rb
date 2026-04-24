require "rails_helper"

RSpec.describe Biodata, type: :model do
  subject { build(:biodata) }

  # ── Associations ────────────────────────────────────────────────────────────

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:created_by).class_name("User").optional }
    it { is_expected.to have_many(:shortlists).dependent(:destroy) }
    it { is_expected.to have_many(:relatives).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:relatives).allow_destroy(true) }
  end

  # ── Validations ─────────────────────────────────────────────────────────────

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_presence_of(:date_of_birth) }

    describe "age_must_be_reasonable" do
      it "is invalid when age is below 18" do
        biodata = build(:biodata, date_of_birth: 17.years.ago.to_date)
        expect(biodata).not_to be_valid
        expect(biodata.errors[:date_of_birth]).to be_present
      end

      it "is invalid when age is above 60" do
        biodata = build(:biodata, date_of_birth: 61.years.ago.to_date)
        expect(biodata).not_to be_valid
        expect(biodata.errors[:date_of_birth]).to be_present
      end

      it "is valid when age is exactly 18" do
        biodata = build(:biodata, date_of_birth: 18.years.ago.to_date)
        expect(biodata).to be_valid
      end

      it "is valid when age is exactly 60" do
        biodata = build(:biodata, date_of_birth: 60.years.ago.to_date)
        expect(biodata).to be_valid
      end
    end
  end

  # ── Enums ───────────────────────────────────────────────────────────────────

  describe "enums" do
    it { is_expected.to define_enum_for(:gender).with_values(male: 0, female: 1) }
    it {
      is_expected.to define_enum_for(:status).with_values(
        draft: 0, pending_review: 1, published: 2, rejected: 3, pending_consent: 4
      )
    }
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  describe ".visible" do
    it "returns only published biodatas ordered by published_at desc" do
      old = create(:biodata, :published, published_at: 2.days.ago)
      new = create(:biodata, :published, published_at: 1.day.ago)
      create(:biodata)                # draft
      create(:biodata, status: :rejected)

      expect(Biodata.visible).to eq([ new, old ])
    end
  end

  describe ".for_gender" do
    it "filters by gender when present" do
      male   = create(:biodata, :published, gender: :male)
      female = create(:biodata, :published, :female)

      expect(Biodata.for_gender("male")).to include(male)
      expect(Biodata.for_gender("male")).not_to include(female)
    end

    it "returns all when value is blank" do
      create(:biodata, :published, gender: :male)
      create(:biodata, :published, :female)

      expect(Biodata.for_gender("").count).to eq(2)
      expect(Biodata.for_gender(nil).count).to eq(2)
    end
  end

  describe ".for_city" do
    it "filters case-insensitively by city" do
      indore = create(:biodata, :published, city: "Indore")
      bhopal = create(:biodata, :published, city: "Bhopal")

      expect(Biodata.for_city("indore")).to include(indore)
      expect(Biodata.for_city("indore")).not_to include(bhopal)
    end
  end

  describe ".for_age_range" do
    it "filters biodatas within the given age range" do
      young = create(:biodata, :published, date_of_birth: 22.years.ago.to_date)
      old   = create(:biodata, :published, date_of_birth: 35.years.ago.to_date)

      result = Biodata.for_age_range(18, 25)
      expect(result).to include(young)
      expect(result).not_to include(old)
    end

    it "returns all when both min and max are blank" do
      create(:biodata, :published, date_of_birth: 22.years.ago.to_date)
      create(:biodata, :published, date_of_birth: 35.years.ago.to_date)

      expect(Biodata.for_age_range(nil, nil).count).to eq(2)
    end
  end

  # ── Status methods ──────────────────────────────────────────────────────────

  describe "#publish!" do
    it "sets status to published and stamps published_at" do
      biodata = create(:biodata, status: :pending_review)
      expect { biodata.publish! }
        .to change { biodata.status }.to("published")
        .and change { biodata.published_at }.from(nil)
    end
  end

  describe "#reject!" do
    it "sets status to rejected and stores the reason" do
      biodata = create(:biodata, status: :pending_review)
      biodata.reject!("Incomplete information")
      expect(biodata).to be_rejected
      expect(biodata.rejection_reason).to eq("Incomplete information")
    end
  end

  describe "#submit_for_review!" do
    it "sets status to pending_review" do
      biodata = create(:biodata)
      expect { biodata.submit_for_review! }
        .to change { biodata.status }.from("draft").to("pending_review")
    end
  end

  # ── Consent methods ─────────────────────────────────────────────────────────

  describe "#admin_created?" do
    it "returns true when created_by_id differs from user_id" do
      admin   = create(:user, :super_admin)
      user    = create(:user)
      biodata = create(:biodata, user: user, created_by: admin)
      expect(biodata.admin_created?).to be true
    end

    it "returns false when created_by_id is nil" do
      biodata = create(:biodata)
      expect(biodata.admin_created?).to be false
    end

    it "returns false when created_by_id equals user_id (self-created)" do
      user    = create(:user)
      biodata = create(:biodata, user: user)
      biodata.update_column(:created_by_id, user.id)
      expect(biodata.admin_created?).to be false
    end
  end

  describe "#consent!" do
    let(:admin)   { create(:user, :super_admin) }
    let(:user)    { create(:user) }
    let(:biodata) { create(:biodata, :pending_consent, user: user, created_by: admin) }

    it "sets status to published" do
      expect { biodata.consent! }.to change { biodata.status }.to("published")
    end

    it "stamps published_at" do
      freeze_time do
        biodata.consent!
        expect(biodata.published_at).to eq(Time.current)
      end
    end

    it "marks user_consented true and stamps consented_at" do
      freeze_time do
        biodata.consent!
        expect(biodata.user_consented).to be true
        expect(biodata.consented_at).to eq(Time.current)
      end
    end
  end

  describe "#decline_consent!" do
    let(:admin)   { create(:user, :super_admin) }
    let(:user)    { create(:user) }
    let(:biodata) { create(:biodata, :pending_consent, user: user, created_by: admin) }

    it "sets status to rejected" do
      expect { biodata.decline_consent! }.to change { biodata.status }.to("rejected")
    end

    it "sets rejection_reason to indicate user declined" do
      biodata.decline_consent!
      expect(biodata.rejection_reason).to eq("User declined consent")
    end
  end

  # ── Instance methods ─────────────────────────────────────────────────────────

  describe "#age" do
    it "calculates age correctly" do
      biodata = build(:biodata, date_of_birth: 28.years.ago.to_date)
      expect(biodata.age).to eq(28)
    end

    it "returns nil when date_of_birth is nil" do
      biodata = build(:biodata, date_of_birth: nil)
      expect(biodata.age).to be_nil
    end
  end

  describe "#display_name" do
    it "returns full_name when locale is :en" do
      biodata = build(:biodata, full_name: "Rahul Sharma", full_name_hi: "राहुल शर्मा")
      I18n.with_locale(:en) { expect(biodata.display_name).to eq("Rahul Sharma") }
    end

    it "returns full_name_hi when locale is :hi and full_name_hi is present" do
      biodata = build(:biodata, full_name: "Rahul Sharma", full_name_hi: "राहुल शर्मा")
      I18n.with_locale(:hi) { expect(biodata.display_name).to eq("राहुल शर्मा") }
    end

    it "falls back to full_name when full_name_hi is blank in :hi locale" do
      biodata = build(:biodata, full_name: "Rahul Sharma", full_name_hi: nil)
      I18n.with_locale(:hi) { expect(biodata.display_name).to eq("Rahul Sharma") }
    end
  end

  describe "#height_display" do
    it "returns formatted feet/inches string with cm" do
      biodata = build(:biodata, height_cm: 170)
      expect(biodata.height_display).to match(/5'7"/)
      expect(biodata.height_display).to include("170 cm")
    end

    it "returns nil when height_cm is nil" do
      biodata = build(:biodata, height_cm: nil)
      expect(biodata.height_display).to be_nil
    end
  end

  describe "#avatar_initial" do
    it "returns the first character of full_name upcased" do
      biodata = build(:biodata, full_name: "rahul")
      expect(biodata.avatar_initial).to eq("R")
    end
  end

  # ── Dependent destroy ────────────────────────────────────────────────────────

  describe "dependent destroy" do
    it "destroys relatives when biodata is destroyed" do
      biodata = create(:biodata)
      create(:relative, biodata: biodata)
      expect { biodata.destroy }.to change(Relative, :count).by(-1)
    end

    it "destroys shortlists when biodata is destroyed" do
      biodata = create(:biodata, :published)
      create(:shortlist, biodata: biodata)
      expect { biodata.destroy }.to change(Shortlist, :count).by(-1)
    end
  end
end
