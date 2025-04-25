class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.string :uuid
      t.integer :customer_id
      t.string :membership_type
      t.decimal :amount
      t.string :status
      t.string :payment_id

      t.timestamps
    end
    add_index :orders, :uuid, unique: true
  end
end
