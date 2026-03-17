FactoryBot.define do
  factory :project do
    name { "RubyConf 2026 Keynote" }
    source_grimoire { build(:grimoire) }
  end
end
