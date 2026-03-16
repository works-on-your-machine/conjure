class SettingsController < ApplicationController
  def show
    @setting = Setting.current
    @vision_count = Vision.count
    @storage_bytes = Vision.total_storage_bytes
  end

  def update
    @setting = Setting.current
    update_params = setting_params.to_h

    # Don't overwrite existing API keys with blank values
    update_params.delete("nano_banana_api_key") if update_params["nano_banana_api_key"].blank? && @setting.nano_banana_api_key.present?
    update_params.delete("llm_api_key") if update_params["llm_api_key"].blank? && @setting.llm_api_key.present?

    @setting.update!(update_params)
    redirect_to settings_path, notice: "Settings updated."
  end

  def clear_unselected
    Vision.where(selected: false).destroy_all
    redirect_to settings_path, notice: "Unselected visions cleared."
  end

  private

  def setting_params
    params.require(:setting).permit(:nano_banana_api_key, :llm_api_key, :default_variations, :default_aspect_ratio)
  end
end
