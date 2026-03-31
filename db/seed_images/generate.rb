PALETTES = [
  { bg1: "#ea580c", bg2: "#dc2626", text: "#fff" },
  { bg1: "#2563eb", bg2: "#7c3aed", text: "#fff" },
  { bg1: "#059669", bg2: "#0d9488", text: "#fff" },
  { bg1: "#d97706", bg2: "#ea580c", text: "#fff" },
  { bg1: "#7c3aed", bg2: "#db2777", text: "#fff" },
  { bg1: "#0369a1", bg2: "#0891b2", text: "#fff" },
  { bg1: "#be123c", bg2: "#9333ea", text: "#fff" },
  { bg1: "#15803d", bg2: "#ca8a04", text: "#fff" },
  { bg1: "#1e3a5f", bg2: "#4a1a6b", text: "#fff" },
  { bg1: "#b91c1c", bg2: "#f59e0b", text: "#fff" }
].freeze

def generate_cover_svg(title_hi, palette_index = 0)
  p = PALETTES[palette_index % PALETTES.length]
  short = title_hi.length > 30 ? title_hi[0..29] + "..." : title_hi

  <<~SVG
    <svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#{p[:bg1]}"/>
          <stop offset="100%" style="stop-color:#{p[:bg2]}"/>
        </linearGradient>
      </defs>
      <rect width="1200" height="630" fill="url(#bg)"/>
      <circle cx="1000" cy="100" r="200" fill="#{p[:text]}" opacity="0.06"/>
      <circle cx="200" cy="500" r="300" fill="#{p[:text]}" opacity="0.04"/>
      <circle cx="900" cy="450" r="150" fill="#{p[:text]}" opacity="0.05"/>
      <rect x="60" y="60" width="8" height="60" rx="4" fill="#{p[:text]}" opacity="0.5"/>
      <text x="90" y="105" font-family="sans-serif" font-size="28" font-weight="bold" fill="#{p[:text]}" opacity="0.7">समाज दर्शन</text>
      <text x="600" y="340" font-family="sans-serif" font-size="42" font-weight="bold" fill="#{p[:text]}" text-anchor="middle" opacity="0.9">#{short}</text>
    </svg>
  SVG
end
