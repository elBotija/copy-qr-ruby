class AddStateAndRelationsToQrCodes < ActiveRecord::Migration[7.0]
  def change
    add_column :qr_codes, :state, :string, default: 'available'
    add_reference :qr_codes, :order, null: true, foreign_key: true
    add_reference :qr_codes, :intermediary, null: true, foreign_key: { to_table: :users }
    add_reference :qr_codes, :sold_to, null: true, foreign_key: { to_table: :users }
  end
end