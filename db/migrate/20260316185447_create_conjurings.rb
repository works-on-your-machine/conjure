class CreateConjurings < ActiveRecord::Migration[8.1]
  def change
    create_table :conjurings do |t|
      t.references :project, null: false, foreign_key: true
      t.text :grimoire_text, null: false
      t.integer :variations_count, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
