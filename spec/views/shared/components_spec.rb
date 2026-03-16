require "rails_helper"

RSpec.describe "Shared UI Components", type: :view do
  describe "shared/_button.html.erb" do
    it "renders a gold variant button" do
      render partial: "shared/button", locals: { text: "Conjure", variant: "gold" }
      expect(rendered).to include("Conjure")
      expect(rendered).to have_css("button")
    end

    it "renders a default variant button" do
      render partial: "shared/button", locals: { text: "Cancel", variant: "default" }
      expect(rendered).to include("Cancel")
    end

    it "renders a ghost variant button" do
      render partial: "shared/button", locals: { text: "AI: Expand", variant: "ghost" }
      expect(rendered).to include("AI: Expand")
    end

    it "renders a danger variant button" do
      render partial: "shared/button", locals: { text: "Delete", variant: "danger" }
      expect(rendered).to include("Delete")
    end
  end

  describe "shared/_card.html.erb" do
    it "renders a card with content" do
      render partial: "shared/card", locals: { content: capture { "<p>Card content</p>".html_safe } }
      expect(rendered).to have_css(".bg-surface")
    end
  end

  describe "shared/_empty_state.html.erb" do
    it "renders with title and description" do
      render partial: "shared/empty_state", locals: {
        title: "Your workshop is empty",
        description: "Every presentation begins as a vision."
      }
      expect(rendered).to include("Your workshop is empty")
      expect(rendered).to include("Every presentation begins as a vision.")
      expect(rendered).to include("✦")
    end
  end

  describe "shared/_label.html.erb" do
    it "renders an uppercase label" do
      render partial: "shared/label", locals: { text: "Theme description" }
      expect(rendered).to include("Theme description")
      expect(rendered).to have_css(".uppercase")
    end
  end

  describe "shared/_form_input.html.erb" do
    it "renders a text input with dark styling" do
      render partial: "shared/form_input", locals: { name: "title", value: "", placeholder: "Enter title" }
      expect(rendered).to have_css("input")
      expect(rendered).to include("Enter title")
    end
  end

  describe "shared/_form_textarea.html.erb" do
    it "renders a textarea with dark styling" do
      render partial: "shared/form_textarea", locals: { name: "description", value: "", placeholder: "Describe..." }
      expect(rendered).to have_css("textarea")
      expect(rendered).to include("Describe...")
    end
  end
end
