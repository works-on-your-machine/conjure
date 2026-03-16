module ApplicationHelper
  def sidebar_sections
    [
      { id: "grimoire", label: "Grimoire", icon: "◈" },
      { id: "incantations", label: "Incantations", icon: "◇" },
      { id: "visions", label: "Visions", icon: "◆" },
      { id: "assembly", label: "Final cut", icon: "▣" }
    ]
  end

  def active_section?(section_id)
    params[:section] == section_id || (params[:section].blank? && section_id == "grimoire")
  end
end
