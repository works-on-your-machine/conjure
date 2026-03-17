class AddSourceGrimoireToProjects < ActiveRecord::Migration[8.1]
  class Project < ApplicationRecord
    self.table_name = "projects"
  end

  class Grimoire < ApplicationRecord
    self.table_name = "grimoires"
  end

  def up
    add_reference :projects, :source_grimoire, foreign_key: { to_table: :grimoires }

    Project.reset_column_information
    Grimoire.reset_column_information

    say_with_time "Creating project-local grimoire copies" do
      Project.find_each do |project|
        source_grimoire = Grimoire.find(project.grimoire_id)
        project_grimoire = Grimoire.create!(
          name: source_grimoire.name,
          description: source_grimoire.description,
          projects_count: 0,
          created_at: project.created_at,
          updated_at: project.updated_at
        )

        project.update_columns(
          grimoire_id: project_grimoire.id,
          source_grimoire_id: source_grimoire.id
        )
      end
    end

    reset_projects_count!
  end

  def down
    Project.reset_column_information
    Grimoire.reset_column_information

    say_with_time "Restoring library grimoires as project grimoires" do
      Project.find_each do |project|
        next if project.source_grimoire_id.blank?

        project_grimoire_id = project.grimoire_id

        project.update_columns(grimoire_id: project.source_grimoire_id)
        Grimoire.where(id: project_grimoire_id).delete_all
      end
    end

    remove_reference :projects, :source_grimoire, foreign_key: { to_table: :grimoires }

    Project.reset_column_information
    Grimoire.reset_column_information
    reset_projects_count!
  end

  private

  def reset_projects_count!
    say_with_time "Resetting grimoire usage counts" do
      Grimoire.update_all(projects_count: 0)

      foreign_key =
        if Project.column_names.include?("source_grimoire_id")
          :source_grimoire_id
        else
          :grimoire_id
        end

      Project.where.not(foreign_key => nil).group(foreign_key).count.each do |grimoire_id, count|
        Grimoire.where(id: grimoire_id).update_all(projects_count: count)
      end
    end
  end
end
