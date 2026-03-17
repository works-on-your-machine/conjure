# Configure ApplicationController.renderer so that Turbo Stream broadcasts
# from background jobs generate correct URLs (instead of defaulting to example.org).
Rails.application.config.after_initialize do
  host = ENV.fetch("HOST", "localhost")
  port = ENV.fetch("PORT", 1618)

  ApplicationController.renderer.defaults.merge!(
    http_host: "#{host}:#{port}",
    https: false
  )
end
