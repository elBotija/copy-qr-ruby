module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_admin!

    def index
      # Estadísticas generales
      @total_orders = Order.count
      @completed_orders = Order.where(status: 'completed').count
      @pending_orders = Order.where(status: 'pending').count
      @revenue_total = Order.where(status: 'completed').sum(:amount)
      
      # Estadísticas de envío
      @orders_shipped = Order.joins(:shipping_info).where(shipping_infos: { status: 'shipped' }).count
      @orders_with_tracking = Order.joins(:shipping_info).where.not(shipping_infos: { tracking_code: [nil, ''] }).count
      @orders_with_invoices = Order.joins(:shipping_info).where.not(shipping_infos: { invoice_filename: [nil, ''] }).count
      
      # Órdenes recientes
      @recent_orders = Order.includes(:customer, :shipping_info).order(created_at: :desc).limit(5)
      
      # Órdenes que requieren atención (completadas pero sin enviar)
      @orders_need_attention = Order.includes(:customer)
                                  .where(status: 'completed')
                                  .joins(:shipping_info)
                                  .where(shipping_infos: { status: 'pending' })
                                  .order(created_at: :asc)
                                  .limit(5)
      
      # Estadísticas por tipo de membresía
      @membership_stats = Order.where(status: 'completed')
                             .group(:membership_type)
                             .count
      
      # Envíos por tipo de transportista
      @carrier_stats = ShippingInfo.where.not(carrier_name: [nil, ''])
                                 .group(:carrier_name)
                                 .count
    end
  end
end