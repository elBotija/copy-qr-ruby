module Admin
  class QrCodesController < ApplicationController
    def new; end

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
