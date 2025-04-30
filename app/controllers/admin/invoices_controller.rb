module Admin
  class InvoicesController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_order, only: [:new, :create, :destroy]

    def new
      @invoice = {
        order_id: @order.id,
        invoice_number: '',
        invoice_date: Date.today
      }
    end

    def create
      if !params[:invoice_file] || !params[:invoice_file].is_a?(ActionDispatch::Http::UploadedFile)
        redirect_to shipping_admin_order_path(@order), alert: 'Debe seleccionar un archivo de factura (PDF).'
        return
      end

      if params[:invoice_file].content_type != "application/pdf"
        redirect_to shipping_admin_order_path(@order), alert: 'El archivo debe ser un PDF.'
        return
      end

      # Generamos un nombre único para el archivo
      filename = "factura-#{@order.uuid}-#{Time.now.to_i}.pdf"
      filepath = Rails.root.join('storage', 'invoices', filename)
      
      # Guardamos el archivo
      File.open(filepath, 'wb') do |file|
        file.write(params[:invoice_file].read)
      end
      
      # Actualizamos la información de envío con los datos de la factura
      @order.shipping_info.update(
        invoice_filename: filename,
        invoice_number: params[:invoice_number],
        invoice_date: params[:invoice_date]
      )
      
      redirect_to shipping_admin_order_path(@order), notice: 'Factura cargada correctamente.'
    end

    def destroy
      if @order.shipping_info.invoice_filename.present?
        # Eliminamos el archivo
        filepath = Rails.root.join('storage', 'invoices', @order.shipping_info.invoice_filename)
        File.delete(filepath) if File.exist?(filepath)
        
        # Actualizamos la información de envío
        @order.shipping_info.update(
          invoice_filename: nil,
          invoice_number: nil,
          invoice_date: nil,
          invoice_sent: false
        )
        
        redirect_to shipping_admin_order_path(@order), notice: 'Factura eliminada correctamente.'
      else
        redirect_to shipping_admin_order_path(@order), alert: 'No hay factura para eliminar.'
      end
    end

    def download
      @order = Order.find(params[:order_id])
      
      if @order.shipping_info&.invoice_filename.present?
        filepath = Rails.root.join('storage', 'invoices', @order.shipping_info.invoice_filename)
        
        if File.exist?(filepath)
          send_file filepath, 
            filename: "Factura-#{@order.uuid}.pdf", 
            type: "application/pdf", 
            disposition: "inline"
        else
          redirect_to admin_order_path(@order), alert: 'El archivo de factura no existe.'
        end
      else
        redirect_to admin_order_path(@order), alert: 'No hay factura asociada a esta orden.'
      end
    end

    private

    def set_order
      @order = Order.find(params[:order_id])
    end
  end
end
