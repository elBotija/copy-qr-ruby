class Order < ApplicationRecord
  belongs_to :customer, optional: true
  has_one :shipping_info, dependent: :destroy
  has_many :memberships, dependent: :destroy
  
  has_many :qr_codes

  validates :uuid, presence: true, uniqueness: true
  
  accepts_nested_attributes_for :shipping_info, allow_destroy: true, update_only: true
  
  after_create :build_default_shipping_info
  
  STATUSES = {
    pending: 'Pendiente',
    completed: 'Completado',
    rejected: 'Rechazado',
    in_process: 'En proceso',
    refunded: 'Reembolsado'
  }
  
  def status_text
    STATUSES[status.to_sym] || status
  end
  
  def build_default_shipping_info
    create_shipping_info if shipping_info.nil?
  end
  
  def customer_full_name
    customer ? "#{customer.first_name} #{customer.last_name}" : 'N/A'
  end
end
