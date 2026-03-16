class Setting < ApplicationRecord
  encrypts :nano_banana_api_key, deterministic: true
  encrypts :llm_api_key, deterministic: true

  def self.current
    first_or_create!
  end
end
