FactoryBot.define do
  factory :vision do
    slide
    conjuring
    position { 1 }
    slide_text { "Talk title with dramatic presentation." }
    prompt { "A dramatic title card with VHS static overlay" }
    selected { false }
  end
end
