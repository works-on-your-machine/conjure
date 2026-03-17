class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_api_keys

  private

  def require_api_keys
    return if self.is_a?(SettingsController)
    return if Setting.current.nano_banana_api_key.present?

    redirect_to settings_path, flash: { notice: "✦ Welcome to Conjure! Set your image generation API key to get started." }
  end
end
