class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.references :grimoire, null: false, foreign_key: true
      t.string :aspect_ratio, default: "16:9"
      t.integer :default_variations, default: 5

      t.timestamps
    end
  end
end
