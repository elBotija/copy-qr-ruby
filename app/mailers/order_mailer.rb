class OrderMailer < ApplicationMailer
  # Correo de confirmación de pago exitoso
  def payment_approved(order)
    @order = order
    @customer = order.customer
    @membership_type = get_membership_name(order.membership_type)
    @link_mi_cuenta = "#{base_url}/mi-cuenta"
    @link_terminos = "#{base_url}/terminos-y-condiciones"
    
    mail(
      to: @customer.email,
      subject: '¡Gracias por tu compra! - Quiero Recordarte'
    )
  end
  
  # Correo para el administrador sobre nueva compra
  def admin_new_purchase(order)
    @order = order
    @customer = order.customer
    @membership_type = get_membership_name(order.membership_type)
    @link_admin_ordenes = "#{base_url}/admin/orders/#{order.id}"
    
    # Determinamos los detalles de la placa según el tipo de membresía
    case order.membership_type
    when 'acompanandote'
      @tipo_placa = 'Estándar'
      @dimensiones_placa = '10x10cm'
      @material_placa = 'Aluminio'
      @tipo_packaging = 'Caja estándar'
    when 'recordandote'
      @tipo_placa = 'Premium'
      @dimensiones_placa = '12x12cm'
      @material_placa = 'Acero inoxidable'
      @tipo_packaging = 'Caja premium'
    when 'siempre'
      @tipo_placa = 'Deluxe'
      @dimensiones_placa = '15x15cm'
      @material_placa = 'Acero inoxidable grabado'
      @tipo_packaging = 'Caja premium con terciopelo'
    else
      @tipo_placa = 'Estándar'
      @dimensiones_placa = '10x10cm'
      @material_placa = 'Aluminio'
      @tipo_packaging = 'Caja estándar'
    end
    
    @fecha_sugerida_envio = (Date.today + 3.days).strftime('%d/%m/%Y')
    
    mail(
      to: 'admin@quierorecordarte.com.ar',
      subject: 'Nueva compra - Quiero Recordarte'
    )
  end
  
  # Correo para enviar próximos pasos al cliente
  def next_steps(order)
    @order = order
    @customer = order.customer
    @membership_type = get_membership_name(order.membership_type)
    @link_activacion = "#{base_url}/activar/#{order.uuid}"
    @link_guia_biografia = "#{base_url}/guia-biografia"
    @link_terminos = "#{base_url}/terminos-y-condiciones"
    
    # Límites según el tipo de membresía
    case order.membership_type
    when 'acompanandote'
      @limite_fotos = 10
      @limite_archivos = 2
      @limite_caracteres = 1000
    when 'recordandote'
      @limite_fotos = 20
      @limite_archivos = 5
      @limite_caracteres = 2000
    when 'siempre'
      @limite_fotos = 50
      @limite_archivos = 10
      @limite_caracteres = 5000
    else
      @limite_fotos = 10
      @limite_archivos = 2
      @limite_caracteres = 1000
    end
    
    mail(
      to: @customer.email,
      subject: 'Próximos pasos para tu Memorial Digital - Quiero Recordarte'
    )
  end
  
  # Correo para enviar bienvenida y configuración de cuenta
  def welcome_setup(order)
    @order = order
    @customer = order.customer
    @membership_type = get_membership_name(order.membership_type)
    @link_activacion = "#{base_url}/activar/#{order.uuid}"
    @link_mi_cuenta = "#{base_url}/mi-cuenta"
    @link_terminos = "#{base_url}/terminos-y-condiciones"
    
    # Límites según el tipo de membresía
    case order.membership_type
    when 'acompanandote'
      @limite_fotos = 10
      @limite_archivos = 2
      @limite_caracteres = 1000
      @tipo_placa = 'Estándar'
    when 'recordandote'
      @limite_fotos = 20
      @limite_archivos = 5
      @limite_caracteres = 2000
      @tipo_placa = 'Premium'
    when 'siempre'
      @limite_fotos = 50
      @limite_archivos = 10
      @limite_caracteres = 5000
      @tipo_placa = 'Deluxe'
    else
      @limite_fotos = 10
      @limite_archivos = 2
      @limite_caracteres = 1000
      @tipo_placa = 'Estándar'
    end
    
    mail(
      to: @customer.email,
      subject: 'Bienvenido/a a Quiero Recordarte'
    )
  end
  
  # Correo para enviar información de seguimiento
  def tracking_info(order)
    @order = order
    @customer = order.customer
    @shipping_info = order.shipping_info
    @membership_type = get_membership_name(order.membership_type)
    @link_seguimiento = get_tracking_link(order.shipping_info)
    @link_mi_cuenta = "#{base_url}/mi-cuenta"
    @link_terminos = "#{base_url}/terminos-y-condiciones"
    
    case order.membership_type
    when 'acompanandote'
      @tipo_placa = 'Estándar'
    when 'recordandote'
      @tipo_placa = 'Premium'
    when 'siempre'
      @tipo_placa = 'Deluxe'
    else
      @tipo_placa = 'Estándar'
    end
    
    mail(
      to: @customer.email,
      subject: '¡Tu QR ha sido enviado! - Quiero Recordarte'
    )
  end
  
  # Correo para enviar factura al cliente
  def invoice(order)
    @order = order
    @customer = order.customer
    @shipping_info = order.shipping_info
    @membership_type = get_membership_name(order.membership_type)
    @link_descarga_factura = "#{base_url}/admin/invoices/download?order_id=#{order.id}"
    @link_terminos = "#{base_url}/terminos-y-condiciones"
    
    # Calculo de montos para la factura
    monto_total = @order.amount.to_f
    @subtotal = (monto_total / 1.21).round(2)  # Asumiendo IVA del 21%
    @iva = (monto_total - @subtotal).round(2)
    @total = monto_total
    
    # Adjuntar la factura si existe
    if @shipping_info&.invoice_filename.present?
      filepath = Rails.root.join('storage', 'invoices', @shipping_info.invoice_filename)
      if File.exist?(filepath)
        attachments["Factura-#{@order.uuid}.pdf"] = File.read(filepath)
      end
    end
    
    mail(
      to: @customer.email,
      subject: 'Factura de Compra - Quiero Recordarte'
    )
  end
  
  private
  
  def get_membership_name(membership_type)
    case membership_type
    when 'acompanandote'
      'Acompañandote'
    when 'recordandote'
      'Recordandote'
    when 'siempre'
      'Siempre Juntos'
    else
      membership_type.titleize
    end
  end
  
  def get_tracking_link(shipping_info)
    return '#' unless shipping_info&.tracking_code.present? && shipping_info&.carrier_name.present?
    
    case shipping_info.carrier_name.downcase
    when 'correo argentino'
      "https://www.correoargentino.com.ar/formularios/e-paq?id=#{shipping_info.tracking_code}"
    when 'oca'
      "https://www.oca.com.ar/envios/#{shipping_info.tracking_code}"
    when 'andreani'
      "https://www.andreani.com/#!/informacionEnvio/#{shipping_info.tracking_code}"
    else
      "#"  # Link genérico si no conocemos la empresa
    end
  end
end