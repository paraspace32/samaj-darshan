require "rails_helper"

RSpec.describe Relative, type: :model do
  subject { build(:relative) }

  # ── Associations ────────────────────────────────────────────────────────────

  describe "associations" do
    it { is_expected.to belong_to(:biodata) }
  end

  # ── Validations ─────────────────────────────────────────────────────────────

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    describe "relative_type inclusion" do
      Relative::TYPES.each do |type|
        it "accepts '#{type}' as a valid type" do
          relative = build(:relative, relative_type: type)
          expect(relative).to be_valid
        end
      end

      it "rejects an unknown type" do
        relative = build(:relative, relative_type: "UnknownRelation")
        expect(relative).not_to be_valid
        expect(relative.errors[:relative_type]).to be_present
      end

      it "rejects a blank type" do
        relative = build(:relative, relative_type: "")
        expect(relative).not_to be_valid
      end
    end
  end

  # ── Constants ───────────────────────────────────────────────────────────────

  describe "TYPES" do
    it "contains exactly the expected relation types" do
      expected = %w[Bhaiya Bhabhi Mama Mami Chacha Chachi Dada Dadi Nana Nani Jijaji Didi Behan]
      expect(Relative::TYPES).to eq(expected)
    end
  end
end
