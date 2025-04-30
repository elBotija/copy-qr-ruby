module Admin
  class OrdersController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_order, only: [:show, :edit, :update, :shipping]

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
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: 'Orden actualizada correctamente.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def shipping
      @order.build_shipping_info if @order.shipping_info.nil?
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
