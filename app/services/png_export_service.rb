require "zip"

class PngExportService
  def initialize(project)
    @project = project
  end

  def generate
    selected_visions = selected_visions_in_order
    return nil if selected_visions.empty?

    buffer = Zip::OutputStream.write_buffer do |zip|
      selected_visions.each_with_index do |(slide, vision), index|
        filename = format("%02d-%s.png", index + 1, slide.title.parameterize)
        zip.put_next_entry(filename)
        zip.write(vision.image.download)
      end
    end

    buffer.string
  end

  def filename
    "#{@project.name.parameterize}-slides.zip"
  end

  private

  def selected_visions_in_order
    @project.slides.order(:position).filter_map { |slide|
      vision = slide.visions.find(&:selected?)
      vision&.image&.attached? ? [ slide, vision ] : nil
    }
  end
end
