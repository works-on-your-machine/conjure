class CreateGrimoires < ActiveRecord::Migration[8.1]
  def change
    create_table :grimoires do |t|
      t.string :name, null: false
      t.text :description
      t.integer :projects_count, default: 0

      t.timestamps
    end
  end
end
