class PdfExportService
  def initialize(project)
    @project = project
  end

  def generate
    selected_visions = selected_visions_in_order
    return nil if selected_visions.empty?

    pdf = Prawn::Document.new(skip_page_creation: true, margin: 0)

    selected_visions.each do |vision|
      image_data = vision.image.attached? ? vision.image.download : nil
      page_size = image_data ? image_dimensions(image_data) : "LETTER"

      pdf.start_new_page(size: page_size, margin: 0)

      next unless image_data

      pdf.image(
        StringIO.new(image_data),
        at: [ 0, pdf.bounds.top ],
        width: pdf.bounds.width,
        height: pdf.bounds.height
      )
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

  def image_dimensions(image_data)
    image = Prawn.image_handler.find(image_data).new(image_data)
    [ image.width, image.height ]
  end
end
