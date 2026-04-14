# Ensure a Setting record exists
Setting.current

# Sample grimoires
pirate = Grimoire.find_or_create_by!(name: "Pirate Broadcast") do |g|
  g.description = <<~DESC
    VHS static. CRT monitors with scan lines. Punk zine meets late-night public access TV.
    Taped-up paper, hand-drawn red circles, glitch effects.

    Colors: Black backgrounds, phosphor green, hot pink and cyan bursts. Warm cream for paper.

    Typography: Monospace terminal, hand-scrawled annotations, bold stamped headlines.

    Era: 1985 meets 2025. Analog warmth through digital decay.
  DESC
end

bauhaus = Grimoire.find_or_create_by!(name: "Bauhaus Clean") do |g|
  g.description = <<~DESC
    Geometric Bauhaus-inspired. Clean cream backgrounds with bold navy, gold, and rust color blocks.
    Watercolor-style illustrations mixed with sharp geometric shapes.

    Typography: Strong serif headlines, clean sans body. Editorial, confident.

    Mood: The intelligent warmth of a well-designed annual report crossed with an art exhibition catalog.
  DESC
end

Grimoire.find_or_create_by!(name: "Vapor Archive") do |g|
  g.description = <<~DESC
    Neon gradients on deep purple. Retro-future Japanese city pop aesthetic.
    Chrome text, sunset gradients, grid floors stretching to infinity.

    Colors: Hot pink, electric cyan, deep indigo, chrome silver.

    Typography: Bold condensed sans, italic accents, glowing outlines.

    Era: 1988 as imagined from 2030.
  DESC
end

# Sample project with slides
project = Project.find_or_create_by!(name: "Talking Shit About AI Agents") do |p|
  p.source_grimoire = pirate
end

slides_data = [
  { title: "Title card", description: "Talk title with dramatic presentation. The name of the talk in large type with supporting visual energy." },
  { title: "The problem", description: "Show a breaking news broadcast frame. Display the core tension — what everyone thinks vs what's actually happening." },
  { title: "The hidden truth", description: "The reframe. The thing nobody is seeing. Visual should feel like a revelation — something being uncovered." },
  { title: "Historical context", description: "Take us back in time. Show the origin of the idea. Green terminal aesthetic, time travel feeling." }
]

slides_data.each_with_index do |data, index|
  project.slides.find_or_create_by!(title: data[:title]) do |s|
    s.description = data[:description]
    s.position = index + 1
  end
end
