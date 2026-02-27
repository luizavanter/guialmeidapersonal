# GA Personal — Redesign Premium "Athletic Luxury"

## Design Philosophy: "Obsidian Kinetics"

A design language born from the intersection of athletic discipline and quiet luxury. Every surface is a study in controlled tension — dark materials that absorb light, accent strokes that cut with surgical precision, typography that commands without shouting. The aesthetic draws from high-end sports architecture: raw concrete gyms with brass fixtures, matte black equipment against polished stone floors.

This is not minimalism for its own sake. It is the visual equivalent of a personal trainer who speaks softly but whose presence fills the room. Surfaces breathe through calculated negative space. Color arrives as a reward — a single luminous accent earned through surrounding restraint. Every pixel is the product of deep expertise, meticulously crafted to appear effortless while being anything but.

Spatial relationships follow athletic principles: rhythm, tension, release. Sections alternate between density and openness like sets and rest periods. Asymmetry creates energy without chaos. The grid exists but is deliberately broken at moments of importance — a hero that bleeds edge-to-edge, a testimonial that floats in isolation, a stat that commands its own territory.

Typography is the skeleton of the design. Headlines are set in a geometric grotesque — clean, authoritative, modern — never condensed or screaming. Body text whispers in a humanist sans that rewards reading. Data speaks through a monospace voice that suggests precision instrumentation. The interplay between these three voices creates a visual cadence that feels authored, not generated.

Texture and depth emerge through subtle material language: frosted glass panels, fine-grain noise overlays on dark surfaces, hairline borders that catch light like brushed metal edges. Shadows are architectural — long, soft, directional — suggesting real light sources rather than generic elevation. Motion is minimal and purposeful: a card that settles into place, a number that counts up, a navigation that slides with weight.

## DFII Score

| Dimension | Score | Rationale |
|---|---|---|
| Aesthetic Impact | 5 | Strong departure from current generic look |
| Context Fit | 5 | Premium fitness in luxury neighborhood — perfect match |
| Implementation Feasibility | 4 | Vue 3 + Tailwind is capable; VitePress has some constraints |
| Performance Safety | 4 | No heavy animations; fonts from Google CDN |
| Consistency Risk | -2 | 3 apps + site require coordinated rollout |
| **DFII Total** | **16** | Excellent — execute fully |

## Concrete Changes

### Logo: GA Monogram
- SVG monogram combining G and A in a geometric lockup
- Horizontal variant: monogram + "GA PERSONAL" wordmark
- Vertical variant: monogram stacked over wordmark
- Favicon: monogram only at 32x32

### Typography Overhaul
- **Headlines:** Space Grotesk (geometric, authoritative, modern — NOT condensed all-caps)
- **Body:** Inter var or DM Sans (clean, readable, professional)
- **Data/Metrics:** JetBrains Mono (keep — it works well)
- Kill the Bebas Neue all-caps-everywhere pattern

### Color Evolution
Keep dark-first, evolve the palette:
- **Coal stays** `#0A0A0A` — the foundation
- **Lime evolves** to a richer gold-green: `#B8E62E` → warm it slightly
- **Add warm neutral** `#8A8578` (stone) for secondary text — warmer than pure gray
- **Ocean becomes subtle** — used sparingly for data/links, not as a second accent
- **Surface layers** get more depth: `#111111`, `#161616`, `#1C1C1C` instead of just coal-light

### Icons
- Replace ALL emojis with Lucide icons (Vue package: `lucide-vue-next`)
- Consistent 24px stroke icons throughout
- No emoji anywhere in the UI

### Layout Revolution (Site)
- Hero: full-bleed asymmetric layout, not centered grid
- Sections: alternate compositions (left-heavy, right-heavy, full-width)
- Break the "title → subtitle → 3-card grid" pattern on every section
- Add editorial touches: pull quotes, large numbers, accent lines with personality

### Component Polish (Admin/Student)
- Login screens: add logo SVG, subtle background texture
- Sidebar: refine with new typography and icon set
- Cards: vary styles (some with accent borders, some floating, some minimal)
- Tables: add subtle row striping with warm undertones
- Empty states: illustrations or meaningful graphics instead of text

### Assets
- Generate proper favicon.ico from logo monogram
- Generate apple-touch-icon, og:image
- Remove vite.svg references
