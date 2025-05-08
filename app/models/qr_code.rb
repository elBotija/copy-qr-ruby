class QrCode < ApplicationRecord
  MEMBERSHIP_TYPES = ['Recordandote', 'Acompañandote', 'Siempre juntos'].freeze
  CHARACTERS = ('a'..'z').to_a.freeze

  belongs_to :memorial, optional: true

  validates :code, presence: true, uniqueness: true
  validates :membership_type, presence: true, inclusion: { in: MEMBERSHIP_TYPES }
  before_validation :generate_code, on: :create

  scope :used, -> { where.not(used_at: nil) }
  # Añadir este scope para consultar los QRs disponibles
  scope :available, -> { where(memorial_id: nil) }

  # Método para verificar si un QR está disponible
  def available?
    memorial_id.nil?
  end

  private

  def generate_code
    loop do
      self.code = generate_random_code
      break unless QrCode.exists?(code: code)
    end
  end

  def generate_random_code
    # Genera el patrón xxx-xxxx-xxx
    parts = [
      generate_random_string(3),
      generate_random_string(4),
      generate_random_string(3)
    ]
    parts.join('-')
  end

  def generate_random_string(length)
    Array.new(length) { CHARACTERS.sample }.join
  end
end