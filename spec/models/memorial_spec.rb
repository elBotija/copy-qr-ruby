require 'rails_helper'

RSpec.describe Memorial, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one_attached(:profile_image) }
    it { is_expected.to have_one_attached(:hero_image) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_length_of(:first_name).is_at_most(100) }

    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(100) }

    it { is_expected.to validate_presence_of(:dob) }

    it { is_expected.to validate_presence_of(:dod) }

    it { is_expected.to validate_length_of(:caption).is_at_most(255).allow_blank }
  end
end
