class CreatePromotionalCampaigns < ActiveRecord::Migration[7.0]
  def change
    create_table :promotional_campaigns do |t|
      t.string :name, null: false
      t.string :utm_campaign, null: false
      t.string :utm_source, default: 'qr_promocional', null: false
      t.string :utm_medium, default: 'offline', null: false
      t.boolean :active, default: true, null: false
      t.integer :qr_count
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    add_index :promotional_campaigns, :utm_campaign, unique: true
  end
end
