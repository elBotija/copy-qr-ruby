class ShippingInfo < ApplicationRecord
  belongs_to :order
  
  validates :tracking_code, uniqueness: true, allow_blank: true
  
  STATUSES = {
    pending: 'Pendiente de envío',
    shipped: 'Enviado',
    in_transit: 'En tránsito',
    delivered: 'Entregado',
    returned: 'Devuelto',
    lost: 'Perdido'
  }
  
  def status_text
    STATUSES[status.to_sym] || status
  end
  
  def has_tracking?
    tracking_code.present? && carrier_name.present?
  end
  
  def has_invoice?
    invoice_filename.present? && invoice_number.present?
  end
end
