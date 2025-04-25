class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships do |t|
      t.references :order_id, null: false, foreign_key: true
      t.references :customer_id, null: false, foreign_key: true
      t.string :membership_type
      t.string :status
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
