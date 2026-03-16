module SettingsHelper
  def mask_api_key(key)
    return nil if key.blank?
    return "•••" if key.length <= 8
    "#{key[0..2]}•••#{key[-3..]}"
  end
end
