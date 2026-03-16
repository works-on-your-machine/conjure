class AddStatusToVisions < ActiveRecord::Migration[8.1]
  def change
    add_column :visions, :status, :integer, default: 0
  end
end
