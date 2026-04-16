require "rails_helper"

RSpec.describe Shortlist, type: :model do
  subject { build(:shortlist) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:biodata) }
  end

  describe "validations" do
    it "prevents a user from shortlisting the same biodata twice" do
      user    = create(:user)
      biodata = create(:biodata, :published)
      create(:shortlist, user: user, biodata: biodata)

      duplicate = build(:shortlist, user: user, biodata: biodata)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:biodata_id]).to be_present
    end

    it "allows the same biodata to be shortlisted by different users" do
      biodata = create(:biodata, :published)
      create(:shortlist, biodata: biodata)

      another = build(:shortlist, biodata: biodata, user: create(:user))
      expect(another).to be_valid
    end

    it "allows a user to shortlist different biodatas" do
      user     = create(:user)
      biodata1 = create(:biodata, :published, user: create(:user))
      biodata2 = create(:biodata, :published, :female, user: create(:user))
      create(:shortlist, user: user, biodata: biodata1)

      second = build(:shortlist, user: user, biodata: biodata2)
      expect(second).to be_valid
    end
  end

  describe "dependent destroy" do
    it "is destroyed when the user is destroyed" do
      shortlist = create(:shortlist)
      user      = shortlist.user
      expect { user.destroy }.to change(Shortlist, :count).by(-1)
    end

    it "is destroyed when the biodata is destroyed" do
      shortlist = create(:shortlist)
      biodata   = shortlist.biodata
      expect { biodata.destroy }.to change(Shortlist, :count).by(-1)
    end
  end
end
