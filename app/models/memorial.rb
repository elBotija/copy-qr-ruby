class Memorial < ApplicationRecord
  MAX_ALLOWED_PHOTOS = 5

  belongs_to :user
  has_one_attached :profile_image
  has_one_attached :hero_image
  has_many_attached :photos

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :dob, presence: true
  validates :dod, presence: true
  validates :caption, length: { maximum: 255, allow_blank: true }
  
  # PIN validation - 4 digits required when memorial is private
  validates :pin_code, length: { is: 4 }, 
                     format: { with: /\A\d{4}\z/, message: "debe ser 4 dígitos numéricos" },
                     presence: true,
                     if: -> { is_private? }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def max_allowed_photos
    # qr_code&.subscription&.max_allowed_photos || MAX_ALLOWED_PHOTOS
    MAX_ALLOWED_PHOTOS
  end
end