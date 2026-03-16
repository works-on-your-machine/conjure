class CreateVisions < ActiveRecord::Migration[8.1]
  def change
    create_table :visions do |t|
      t.references :slide, null: false, foreign_key: true
      t.references :conjuring, null: false, foreign_key: true
      t.integer :position
      t.text :slide_text
      t.text :prompt
      t.text :refinement
      t.boolean :selected, default: false

      t.timestamps
    end
  end
end
