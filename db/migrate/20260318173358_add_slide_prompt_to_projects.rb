class AddSlidePromptToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :slide_prompt, :text
  end
end
