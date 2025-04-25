class CreateQrCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :qr_codes do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :membership_type, null: false
      t.datetime :used_at, default: nil

      t.timestamps
    end
  end
end
