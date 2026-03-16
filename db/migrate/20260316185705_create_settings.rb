class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :nano_banana_api_key
      t.string :llm_api_key
      t.integer :default_variations, default: 5
      t.string :default_aspect_ratio, default: "16:9"

      t.timestamps
    end
  end
end
