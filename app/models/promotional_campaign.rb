class PromotionalCampaign < ApplicationRecord
  BASE_URL = 'https://www.quierorecordarte.com.ar'.freeze

  validates :name, presence: true
  validates :utm_campaign, presence: true, uniqueness: true
  validates :qr_count, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "debe ser posterior a la fecha de inicio")
    end
  end
end
