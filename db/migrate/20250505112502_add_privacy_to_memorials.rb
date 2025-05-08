class AddPrivacyToMemorials < ActiveRecord::Migration[7.1]
  def change
    add_column :memorials, :is_private, :boolean, default: false
    add_column :memorials, :pin_code, :string
  end
end
