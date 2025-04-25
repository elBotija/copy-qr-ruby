module Admin
  class PromoController < ApplicationController
    def index
      @campaigns = PromotionalCampaign.order(created_at: :desc)
    end

    def show
      campaign = PromotionalCampaign.find(params[:id])

      render json: {
        base_url: PromotionalCampaign::BASE_URL,
        utm_campaign: campaign.utm_campaign,
        qr_count: campaign.qr_count,
        utm_source: campaign.utm_source,
        utm_medium: campaign.utm_medium
      }
    end

    def create
      @campaign = PromotionalCampaign.new(campaign_params)

      if @campaign.save
        render json: { campaign: @campaign }, status: :created
      else
        render json: { errors: @campaign.errors
        }, status: :unprocessable_entity
      end
    end

    private

    def campaign_params
      params.require(:campaign).permit(
        :active,
        :end_date,
        :name,
        :qr_count,
        :start_date,
        :utm_campaign
      )
    end
  end
end
