class QrCode < ApplicationRecord
  MEMBERSHIP_TYPES = ['Recordandote', 'Acompañandote', 'Siempre juntos'].freeze
  STATES = ['available', 'assigned_to_order', 'consigned', 'sold', 'associated_to_memorial'].freeze
  CHARACTERS = ('a'..'z').to_a.freeze

  belongs_to :memorial, optional: true
  belongs_to :order, optional: true
  belongs_to :intermediary, optional: true, class_name: 'User' # Para futuro uso
  belongs_to :sold_to, optional: true, class_name: 'User'     # Usuario final
  
  validates :code, presence: true, uniqueness: true
  validates :membership_type, presence: true, inclusion: { in: MEMBERSHIP_TYPES }
  validates :state, inclusion: { in: STATES }
  
  before_validation :generate_code, on: :create
  before_validation :set_default_state, on: :create

  scope :used, -> { where.not(used_at: nil) }
  scope :available, -> { where(state: 'available') }
  scope :by_membership_type, ->(type) { where(membership_type: type) }
  
  # Métodos para cambiar estados
  def assign_to_order(order)
    update(order: order, state: 'assigned_to_order')
  end
  
  def consign_to(intermediary)
    update(intermediary: intermediary, state: 'consigned')
  end
  
  def mark_as_sold(user)
    update(sold_to: user, state: 'sold')
  end
  
  def associate_to_memorial(memorial)
    update(memorial: memorial, state: 'associated_to_memorial')
  end
  
  # Método para verificar si un QR está disponible
  def available?
    state == 'available'
  end
  
  private
  
  def set_default_state
    self.state ||= 'available'
  end

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