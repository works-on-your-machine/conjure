class PdfExportService
  def initialize(project)
    @project = project
  end

  def generate
    selected_visions = selected_visions_in_order
    return nil if selected_visions.empty?

    pdf = Prawn::Document.new(page_size: "LETTER", margin: 0)

    selected_visions.each_with_index do |vision, index|
      pdf.start_new_page unless index == 0

      if vision.image.attached?
        image_data = vision.image.download
        pdf.image StringIO.new(image_data), fit: [ pdf.bounds.width, pdf.bounds.height ], position: :center, vposition: :center
      end
    end

    pdf.render
  end

  def filename
    "#{@project.name.parameterize}.pdf"
  end

  private

  def selected_visions_in_order
    @project.slides.order(:position).filter_map { |slide|
      slide.visions.find(&:selected?)
    }
  end
end
