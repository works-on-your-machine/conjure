module ApplicationHelper
  def sidebar_sections
    [
      { id: "grimoire", label: "Grimoire", icon: sidebar_icon_grimoire },
      { id: "incantations", label: "Incantations", icon: sidebar_icon_incantations },
      { id: "visions", label: "Visions", icon: sidebar_icon_visions },
      { id: "assembly", label: "Final cut", icon: sidebar_icon_assembly }
    ]
  end

  private

  # Inline SVG icons for sidebar — 16x16, stroke-based, currentColor
  def sidebar_icon_grimoire
    '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12.5V3a1.5 1.5 0 0 1 1.5-1.5H13v10H3.5A1.5 1.5 0 0 0 2 13v0a1.5 1.5 0 0 0 1.5 1.5H13"/><path d="M5.5 5.5h5"/></svg>'.html_safe
  end

  def sidebar_icon_incantations
    '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3h8M5 8h8M5 13h5"/><circle cx="2.5" cy="3" r="0.5" fill="currentColor" stroke="none"/><circle cx="2.5" cy="8" r="0.5" fill="currentColor" stroke="none"/><circle cx="2.5" cy="13" r="0.5" fill="currentColor" stroke="none"/></svg>'.html_safe
  end

  def sidebar_icon_visions
    '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="1.5" y="3" width="13" height="10" rx="1.5"/><path d="M1.5 10.5l3-3 2.5 2.5 3-3.5 4.5 4.5"/></svg>'.html_safe
  end

  def sidebar_icon_assembly
    '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="1.5" y="1.5" width="5.5" height="5.5" rx="1"/><rect x="9" y="1.5" width="5.5" height="5.5" rx="1"/><rect x="1.5" y="9" width="5.5" height="5.5" rx="1"/><rect x="9" y="9" width="5.5" height="5.5" rx="1"/></svg>'.html_safe
  end

  public

  def active_section?(section_id)
    params[:section] == section_id || (params[:section].blank? && section_id == "grimoire")
  end

  # Reusable button class strings — use on link_to, f.submit, button_to, etc.
  def btn_gold(extra = "")
    "bg-gold text-plum-deep px-6 py-2.5 rounded-md font-body text-sm font-semibold no-underline cursor-pointer border-none shadow-[0_4px_20px_var(--color-gold-glow-strong)] #{extra}".strip
  end

  def btn_default(extra = "")
    "bg-surface text-conjure-text-muted px-4 py-2 rounded-md text-[13px] no-underline border border-conjure-border hover:border-conjure-border-hover transition-all #{extra}".strip
  end

  def btn_danger(extra = "")
    "bg-transparent text-danger px-4 py-2 rounded-md font-body text-[13px] border border-danger/30 cursor-pointer #{extra}".strip
  end
end
