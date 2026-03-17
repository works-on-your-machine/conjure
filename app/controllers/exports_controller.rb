class ExportsController < ApplicationController
  before_action :set_project

  def pdf
    service = PdfExportService.new(@project)
    pdf_data = service.generate

    if pdf_data
      send_data pdf_data, filename: service.filename, type: "application/pdf", disposition: "attachment"
    else
      redirect_to assembly_project_path(@project), alert: "No selected visions to export."
    end
  end

  def png
    service = PngExportService.new(@project)
    zip_data = service.generate

    if zip_data
      send_data zip_data, filename: service.filename, type: "application/zip", disposition: "attachment"
    else
      redirect_to assembly_project_path(@project), alert: "No selected visions to export."
    end
  end

  def project_zip
    service = ProjectExportService.new(@project)
    zip_data = service.generate

    send_data zip_data, filename: service.filename, type: "application/zip", disposition: "attachment"
  end

  private

  def set_project
    @project = Project.includes(:grimoire, slides: { visions: { image_attachment: :blob } }, conjurings: { visions: { image_attachment: :blob } }).find(params[:project_id])
  end
end
