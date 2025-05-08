module Admin
  class QrCodesController < ApplicationController
    def new; end

    def index
      @qr_codes = QrCode.all.includes(:memorial).order(created_at: :desc)
    end
    
    def release
      @qr_code = QrCode.find(params[:id])
      
      if @qr_code.memorial.present?
        @memorial = @qr_code.memorial
        @qr_code.update(memorial_id: nil)
        redirect_to admin_qr_codes_path, notice: "QR code #{@qr_code.code} liberado correctamente del memorial '#{@memorial.full_name}'."
      else
        redirect_to admin_qr_codes_path, alert: 'Este QR code ya está disponible.'
      end
    end

    def create
      count = params[:count].to_i || 2
      membership_type = params[:membership_type]

      qr_codes = ActiveRecord::Base.transaction do
        count.times.map do
          QrCode.create!(membership_type: membership_type)
        end
      end

      render json: { qr_codes: }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
