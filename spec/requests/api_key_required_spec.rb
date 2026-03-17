require "rails_helper"

RSpec.describe "API key requirement", type: :request do
  before do
    # Clear the key set by the global before hook
    Setting.current.update_columns(nano_banana_api_key: nil)
  end

  it "redirects to settings when no image API key is set" do
    get root_path
    expect(response).to redirect_to(settings_path)
    follow_redirect!
    expect(response.body).to include("Set your image generation API key")
  end

  it "allows access to the settings page without an API key" do
    get settings_path
    expect(response).to have_http_status(:ok)
  end

  it "allows access after API key is set" do
    Setting.current.update_columns(nano_banana_api_key: "my-key")
    get root_path
    expect(response).to have_http_status(:ok)
  end
end
