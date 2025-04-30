class CreateShippingInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :shipping_infos do |t|
      t.references :order, null: false, foreign_key: true
      t.string :tracking_code
      t.string :carrier_name
      t.string :status, default: 'pending'
      t.date :shipped_date
      t.date :estimated_delivery_date
      t.text :notes
      t.string :invoice_filename
      t.boolean :invoice_sent, default: false
      t.boolean :tracking_notification_sent, default: false

      t.timestamps
    end
  end
end
