class AddOutlineToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :outline, :text
  end
end
