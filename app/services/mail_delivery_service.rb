class MailDeliveryService
  def self.process_new_order(order)
    if order.status == 'completed'
      # Enviar correo de confirmación de pago al cliente
      OrderMailer.payment_approved(order).deliver_later
      
      # Enviar correo de aviso al administrador
      OrderMailer.admin_new_purchase(order).deliver_later
      
      # Programar los siguientes correos con un intervalo
      # Próximos pasos - 30 minutos después
      OrderMailer.next_steps(order).deliver_later(wait: 30.minutes)
      
      # Bienvenida y configuración - 2 horas después
      OrderMailer.welcome_setup(order).deliver_later(wait: 2.hours)
    end
  end
  
  def self.process_tracking_update(order)
    if order.shipping_info.tracking_code.present? && 
       order.shipping_info.carrier_name.present? && 
       !order.shipping_info.tracking_notification_sent?
      
      # Enviar correo con información de seguimiento
      OrderMailer.tracking_info(order).deliver_later
      
      # Marcar como enviado
      order.shipping_info.update(tracking_notification_sent: true)
    end
  end
  
  def self.process_invoice_upload(order)
    if order.shipping_info.invoice_filename.present? && 
       !order.shipping_info.invoice_sent?
      
      # Enviar correo con la factura
      OrderMailer.invoice(order).deliver_later
      
      # Marcar como enviado
      order.shipping_info.update(invoice_sent: true)
    end
  end
  
  # Nuevo método para actualizar estado de envío y enviar notificaciones
  def self.process_shipping_status_change(order, old_status, new_status)
    # Si el estado cambió a "shipped" y hay información de seguimiento
    if old_status != 'shipped' && new_status == 'shipped' && 
       order.shipping_info.tracking_code.present? && 
       order.shipping_info.carrier_name.present?
      
      # Enviar correo de seguimiento si no se ha enviado aún
      if !order.shipping_info.tracking_notification_sent?
        OrderMailer.tracking_info(order).deliver_later
        order.shipping_info.update(tracking_notification_sent: true)
      end
    end
  end
end
