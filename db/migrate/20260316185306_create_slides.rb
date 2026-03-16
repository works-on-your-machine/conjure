class CreateSlides < ActiveRecord::Migration[8.1]
  def change
    create_table :slides do |t|
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
