class CreateMemorials < ActiveRecord::Migration[7.1]
  def change
    create_table :memorials do |t|
      t.references :user, null: false, foreign_key: true
      t.date :dob
      t.date :dod
      t.string :first_name, limit: 100
      t.string :last_name, limit: 100
      t.integer :religion
      t.text :bio
      t.string :caption, limit: 255

      t.timestamps
    end
  end
end
