require "zip"
require "json"

class ProjectExportService
  def initialize(project)
    @project = project
  end

  def generate
    prefix = @project.name.parameterize

    buffer = Zip::OutputStream.write_buffer do |zip|
      # Grimoire
      zip.put_next_entry("#{prefix}/grimoire.txt")
      zip.write(@project.grimoire.description)

      # Slides
      @project.slides.order(:position).each_with_index do |slide, index|
        filename = format("%02d-%s.txt", index + 1, slide.title.parameterize)
        zip.put_next_entry("#{prefix}/slides/#{filename}")
        zip.write("#{slide.title}\n\n#{slide.description}")
      end

      # Conjurings with visions
      @project.conjurings.includes(visions: { image_attachment: :blob }).order(:created_at).each_with_index do |conjuring, ci|
        run_dir = "#{prefix}/conjurings/run-#{ci + 1}"

        # Metadata
        metadata = {
          conjuring_id: conjuring.id,
          created_at: conjuring.created_at,
          grimoire_text: conjuring.grimoire_text,
          variations_count: conjuring.variations_count,
          status: conjuring.status,
          visions: conjuring.visions.map { |v|
            {
              id: v.id,
              slide_id: v.slide_id,
              position: v.position,
              slide_text: v.slide_text,
              prompt: v.prompt,
              refinement: v.refinement,
              selected: v.selected,
              status: v.status
            }
          }
        }

        zip.put_next_entry("#{run_dir}/metadata.json")
        zip.write(JSON.pretty_generate(metadata))

        # Vision images
        conjuring.visions.each do |vision|
          next unless vision.image.attached?
          filename = "slide-#{vision.slide_id}-v#{vision.position}.png"
          zip.put_next_entry("#{run_dir}/#{filename}")
          zip.write(vision.image.download)
        end
      end
    end

    buffer.string
  end

  def filename
    "#{@project.name.parameterize}-project.zip"
  end
end
