# Load Active Record encryption keys from a local file.
# Generated automatically by bin/setup if not present.
# This file is gitignored — each installation generates its own keys.

key_file = Rails.root.join("config", "active_record_encryption.key")

if key_file.exist?
  keys = YAML.safe_load(key_file.read)
  Rails.application.config.active_record.encryption.primary_key = keys["primary_key"]
  Rails.application.config.active_record.encryption.deterministic_key = keys["deterministic_key"]
  Rails.application.config.active_record.encryption.key_derivation_salt = keys["key_derivation_salt"]
elsif Rails.env.test?
  # Use fixed keys in test so specs are deterministic
  Rails.application.config.active_record.encryption.primary_key = "test-primary-key-for-encryption"
  Rails.application.config.active_record.encryption.deterministic_key = "test-deterministic-key-encrypt"
  Rails.application.config.active_record.encryption.key_derivation_salt = "test-key-derivation-salt-value"
end
