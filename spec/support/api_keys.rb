# Most specs need an API key set to bypass the require_api_keys check.
# Specs that explicitly test the missing-key redirect should clear it.
RSpec.configure do |config|
  config.before(:each, type: :request) do
    Setting.current.update_columns(nano_banana_api_key: "test-key-for-specs")
  end
end
