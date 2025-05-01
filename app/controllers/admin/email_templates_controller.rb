module Admin
  class EmailTemplatesController < ApplicationController
    before_action :authenticate_admin!
    
    def index
      @templates = [
        { 
          id: 'payment_approved', 
          name: 'Confirmación de Pago', 
          description: 'Enviado al cliente cuando su pago es aprobado' 
        },
        { 
          id: 'admin_new_purchase', 
          name: 'Aviso de Nueva Compra', 
          description: 'Enviado a los administradores cuando hay una nueva compra' 
        },
        { 
          id: 'next_steps', 
          name: 'Próximos Pasos', 
          description: 'Guía al cliente sobre cómo proceder después de la compra' 
        },
        { 
          id: 'welcome_setup', 
          name: 'Bienvenida y Configuración', 
          description: 'Instrucciones para activar la cuenta y detalles de la membresía' 
        },
        { 
          id: 'tracking_info', 
          name: 'Información de Seguimiento', 
          description: 'Enviado cuando se registra un código de seguimiento para el envío' 
        },
        { 
          id: 'invoice', 
          name: 'Factura', 
          description: 'Enviado al cliente cuando se carga una factura en el sistema' 
        }
      ]
    end
    
    def preview
      @template_id = params[:id]
      # Buscar una orden completada para la vista previa
      @order = Order.where(status: 'completed').includes(:customer, :shipping_info).first
      
      if @order.nil?
        redirect_to admin_email_templates_path, alert: 'No hay órdenes completadas para la vista previa'
        return
      end
      
      case @template_id
      when 'payment_approved'
        @mail = OrderMailer.payment_approved(@order)
      when 'admin_new_purchase'
        @mail = OrderMailer.admin_new_purchase(@order)
      when 'next_steps'
        @mail = OrderMailer.next_steps(@order)
      when 'welcome_setup'
        @mail = OrderMailer.welcome_setup(@order)
      when 'tracking_info'
        # Asegurarse de que la orden tenga información de seguimiento
        unless @order.shipping_info&.tracking_code.present?
          @order.shipping_info ||= @order.build_shipping_info
          @order.shipping_info.update(
            tracking_code: 'DEMO-TRACKING-123456',
            carrier_name: 'Correo Argentino',
            shipped_date: Date.today,
            estimated_delivery_date: Date.today + 5.days
          )
        end
        @mail = OrderMailer.tracking_info(@order)
      when 'invoice'
        # Asegurarse de que la orden tenga información de factura
        unless @order.shipping_info&.invoice_filename.present?
          @order.shipping_info ||= @order.build_shipping_info
          @order.shipping_info.update(
            invoice_number: 'A-0001-00000123',
            invoice_date: Date.today
          )
        end
        @mail = OrderMailer.invoice(@order)
      else
        redirect_to admin_email_templates_path, alert: 'Plantilla no válida'
        return
      end
      
      # Renderizar la vista previa de manera segura
      if @mail.html_part && @mail.html_part.body
        render html: @mail.html_part.body.decoded.html_safe, layout: 'application'
      elsif @mail.body && @mail.body.respond_to?(:decoded)
        render html: @mail.body.decoded.html_safe, layout: 'application'
      elsif @mail.body
        render html: @mail.body.to_s.html_safe, layout: 'application'
      else
        render html: "<p>No se pudo generar una vista previa para esta plantilla.</p>".html_safe, layout: 'application'
      end
    end
    
    def test
      @template_id = params[:id]
      @email = params[:email]
      
      unless @email.present? && @email.match(/\A[^@\s]+@[^@\s]+\z/)
        redirect_to admin_email_templates_path, alert: 'Dirección de correo no válida'
        return
      end
      
      # Buscar una orden completada para la prueba
      @order = Order.where(status: 'completed').includes(:customer, :shipping_info).first
      
      if @order.nil?
        redirect_to admin_email_templates_path, alert: 'No hay órdenes completadas para la prueba'
        return
      end
      
      case @template_id
      when 'payment_approved'
        OrderMailer.payment_approved(@order).deliver_later
      when 'admin_new_purchase'
        OrderMailer.admin_new_purchase(@order).deliver_later
      when 'next_steps'
        OrderMailer.next_steps(@order).deliver_later
      when 'welcome_setup'
        OrderMailer.welcome_setup(@order).deliver_later
      when 'tracking_info'
        # Asegurarse de que la orden tenga información de seguimiento
        unless @order.shipping_info&.tracking_code.present?
          @order.shipping_info ||= @order.build_shipping_info
          @order.shipping_info.update(
            tracking_code: 'DEMO-TRACKING-123456',
            carrier_name: 'Correo Argentino',
            shipped_date: Date.today,
            estimated_delivery_date: Date.today + 5.days
          )
        end
        OrderMailer.tracking_info(@order).deliver_later
      when 'invoice'
        # Asegurarse de que la orden tenga información de factura
        unless @order.shipping_info&.invoice_filename.present?
          @order.shipping_info ||= @order.build_shipping_info
          @order.shipping_info.update(
            invoice_number: 'A-0001-00000123',
            invoice_date: Date.today
          )
        end
        OrderMailer.invoice(@order).deliver_later
      else
        redirect_to admin_email_templates_path, alert: 'Plantilla no válida'
        return
      end
      
      redirect_to admin_email_templates_path, notice: "Correo de prueba enviado a #{@email}"
    end
  end
end