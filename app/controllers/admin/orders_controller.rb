module Admin
  class OrdersController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_order, only: [:show, :edit, :update, :shipping, :send_tracking, :send_invoice, :assign_qr, :release_qr]

    def index
      @orders = Order.includes(:customer, :shipping_info).order(created_at: :desc)
      
      # Filtrar por estado si se proporciona
      if params[:status].present?
        @orders = @orders.where(status: params[:status])
      end
      
      # Filtrar por estado de envío si se proporciona
      if params[:shipping_status].present?
        @orders = @orders.joins(:shipping_info).where(shipping_infos: { status: params[:shipping_status] })
      end
    end

    def show
    end

    def edit
    end

    def update
      old_status = @order.status
      old_shipping_status = @order.shipping_info&.status
      
      if @order.update(order_params)
        # Comprobar si se cambió el estado a completed
        if old_status != 'completed' && @order.status == 'completed'
          MailDeliveryService.process_new_order(@order)
        end
        
        # Comprobar si cambió el estado de envío
        if @order.shipping_info && old_shipping_status != @order.shipping_info.status
          MailDeliveryService.process_shipping_status_change(@order, old_shipping_status, @order.shipping_info.status)
        end
        
        # Si se actualizó tracking y ya está en estado shipped
        if @order.shipping_info && @order.shipping_info.status == 'shipped' && 
           @order.shipping_info.tracking_code.present? && 
           @order.shipping_info.carrier_name.present? && 
           !@order.shipping_info.tracking_notification_sent?
          
          MailDeliveryService.process_tracking_update(@order)
        end
        
        redirect_to admin_order_path(@order), notice: 'Orden actualizada correctamente.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def shipping
      @order.build_shipping_info if @order.shipping_info.nil?
    end
    
    def send_tracking
      if @order.shipping_info&.has_tracking?
        MailDeliveryService.process_tracking_update(@order)
        redirect_to shipping_admin_order_path(@order), notice: 'Información de seguimiento enviada por correo correctamente.'
      else
        redirect_to shipping_admin_order_path(@order), alert: 'No hay información de seguimiento completa para enviar.'
      end
    end
    
    def send_invoice
      if @order.shipping_info&.invoice_filename.present?
        MailDeliveryService.process_invoice_upload(@order)
        redirect_to shipping_admin_order_path(@order), notice: 'Factura enviada por correo correctamente.'
      else
        redirect_to shipping_admin_order_path(@order), alert: 'No hay factura cargada para enviar.'
      end
    end
    
    def assign_qr
      @order = Order.find(params[:id])
      
      # Mapeo de tipos de membresías (minúsculas a formato del QR)
      membership_type_mapping = {
        'acompanandote' => 'Acompañandote',
        'recordandote' => 'Recordandote',
        'siempre' => 'Siempre juntos'
      }
      
      # Obtener el tipo de membresía en el formato de QrCode
      qr_membership_type = membership_type_mapping[@order.membership_type] || @order.membership_type
      
      # Determinar el código QR (por selección o escaneo)
      if params[:scanned_code].present?
        @qr_code = QrCode.available.find_by(code: params[:scanned_code])
        
        if @qr_code.nil?
          scanned_qr = QrCode.find_by(code: params[:scanned_code])
          
          if scanned_qr.nil?
            redirect_to shipping_admin_order_path(@order), 
              alert: "El código QR escaneado no existe en el sistema."
          else
            redirect_to shipping_admin_order_path(@order), 
              alert: "El código QR escaneado ya está asignado (#{scanned_qr.state})."
          end
          return
        end
      else
        @qr_code = QrCode.available.find_by(id: params[:qr_code_id])
        
        if @qr_code.nil?
          redirect_to shipping_admin_order_path(@order), 
            alert: "Por favor, seleccione un código QR válido."
          return
        end
      end
      
      # Verificar que el tipo de membresía coincide, usando el tipo mapeado
      if @qr_code.membership_type != qr_membership_type
        redirect_to shipping_admin_order_path(@order), 
          alert: "Error: Este QR es para '#{@qr_code.membership_type}' pero la orden es para '#{@order.membership_type}' (#{qr_membership_type})."
        return
      end
      
      # Asociar QR a la orden
      if @qr_code.assign_to_order(@order)
        redirect_to shipping_admin_order_path(@order), 
          notice: "QR '#{@qr_code.code}' asociado correctamente a esta orden."
      else
        redirect_to shipping_admin_order_path(@order), 
          alert: "Error al asociar el QR: #{@qr_code.errors.full_messages.join(', ')}"
      end
    end
    
    def release_qr
      @order = Order.find(params[:id])
      @qr_code = QrCode.find(params[:qr_id])
      
      if @qr_code.order_id != @order.id
        redirect_to shipping_admin_order_path(@order), 
          alert: "Este QR no está asociado a esta orden."
        return
      end
      
      # Liberar el QR
      @qr_code.update(order_id: nil, state: 'available')
      
      redirect_to shipping_admin_order_path(@order), 
        notice: "QR '#{@qr_code.code}' desvinculado correctamente de esta orden."
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :status,
        shipping_info_attributes: [
          :id, :tracking_code, :carrier_name, :status, 
          :shipped_date, :estimated_delivery_date, :notes, 
          :invoice_filename, :invoice_sent, :tracking_notification_sent
        ]
      )
    end
  end
end
