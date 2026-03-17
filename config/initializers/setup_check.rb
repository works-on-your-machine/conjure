# Ensure bin/setup has been run before the app starts.
# The encryption key file is generated during setup — if it's missing,
# the app can't function (API keys can't be stored/read).

unless Rails.env.test?
  key_file = Rails.root.join("config", "active_record_encryption.key")
  unless key_file.exist?
    abort <<~MSG

      ✦ Conjure needs to be set up first!

      Run:  bin/setup

      This generates encryption keys and prepares the database.
      You only need to do this once.

    MSG
  end
end
