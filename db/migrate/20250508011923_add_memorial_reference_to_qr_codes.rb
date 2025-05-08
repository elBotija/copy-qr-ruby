class AddMemorialReferenceToQrCodes < ActiveRecord::Migration[7.1]
  def change
    add_reference :qr_codes, :memorial, null: true, foreign_key: true
  end
end
