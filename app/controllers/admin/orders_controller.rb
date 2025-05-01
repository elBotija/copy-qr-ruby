module Admin
  class OrdersController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_order, only: [:show, :edit, :update, :shipping, :send_tracking, :send_invoice]

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
