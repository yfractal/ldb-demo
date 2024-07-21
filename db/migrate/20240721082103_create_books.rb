class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :books do |t|
      t.string :name
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
