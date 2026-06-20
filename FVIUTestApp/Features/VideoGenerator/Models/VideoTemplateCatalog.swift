import SwiftUI

/// Single source of truth for the AI Video template catalog.
///
/// Templates are bundled with the app (their preview photos ship in the asset catalog), not
/// fetched from the backend — the Pixverse API only generates video from a prompt/photo, it does
/// not serve a template list. Keeping the catalog as a static, in-memory model is intentional and
/// matches how chat/video history already work in this app (UserDefaults + Codable, no database):
/// the data volume here is small and fixed, so a local DB would be unjustified complexity.
enum VideoTemplateCatalog {
    /// Figma category order — "Popular" always leads, the rest follow the same order as the tabs
    /// in the "AI Video" screen.
    static let categoryOrder = ["Popular", "Funny", "Sad", "Trends", "Design"]

    static let templates: [VideoTemplate] = [
        VideoTemplate(
            title: "Clay Fool",
            category: "Popular",
            prompt: "Turn this photo into a warm clay animation scene with soft studio light and playful motion.",
            colors: [.pink, .orange]
        ),
        VideoTemplate(
            title: "Android Dream",
            category: "Popular",
            prompt: "Animate this portrait inside a sleek sci-fi helmet with soft volumetric light and a slow push-in.",
            colors: [.cyan, .blue]
        ),
        VideoTemplate(
            title: "Neon Runner",
            category: "Trends",
            prompt: "Create a dynamic neon cyberpunk video with rain, reflections and smooth camera movement.",
            colors: [.blue, .purple]
        ),
        VideoTemplate(
            title: "Dream Portrait",
            category: "Popular",
            prompt: "Animate this portrait with cinematic lighting, subtle expression and clean background depth.",
            colors: [.mint, .cyan],
            requiredPhotoCount: 2
        ),
        VideoTemplate(
            title: "Funny Loop",
            category: "Funny",
            prompt: "Make a short funny loop with expressive character motion and bright cheerful timing.",
            colors: [.yellow, .pink]
        ),
        VideoTemplate(
            title: "Soft Memory",
            category: "Sad",
            prompt: "Create a nostalgic slow video with gentle camera movement, warm grain and emotional atmosphere.",
            colors: [.indigo, .gray]
        ),
        VideoTemplate(
            title: "Product Glow",
            category: "Design",
            prompt: "Create a polished product-style video with premium lighting, clean reflections and slow reveal.",
            colors: [.purple, .pink],
            requiredPhotoCount: 2
        ),
        VideoTemplate(
            title: "Together Again",
            category: "Sad",
            prompt: "Blend two portraits into one nostalgic reunion scene with warm light and a gentle camera drift.",
            colors: [.orange, .indigo],
            requiredPhotoCount: 2
        ),

        // Each category needs at least 6 templates so the grid fills out the way it does in Figma.
        VideoTemplate(
            title: "Studio Light",
            category: "Popular",
            prompt: "Animate this portrait with crisp studio lighting and a smooth, confident camera drift.",
            colors: [.cyan, .pink]
        ),
        VideoTemplate(
            title: "Golden Hour",
            category: "Popular",
            prompt: "Bathe this photo in warm golden-hour light with gentle motion and soft lens flare.",
            colors: [.orange, .yellow],
            requiredPhotoCount: 2
        ),
        VideoTemplate(
            title: "Cyber Bloom",
            category: "Popular",
            prompt: "Surround this portrait with blooming cyber-floral light particles and a slow rotate.",
            colors: [.purple, .cyan]
        ),

        VideoTemplate(
            title: "Wacky Bounce",
            category: "Funny",
            prompt: "Make this photo bounce and squash with cartoonish energy and a bright comedic beat.",
            colors: [.yellow, .orange]
        ),
        VideoTemplate(
            title: "Goofy Zoom",
            category: "Funny",
            prompt: "Add an exaggerated comedic zoom-in with wobbly motion and playful timing.",
            colors: [.pink, .yellow]
        ),
        VideoTemplate(
            title: "Silly Spin",
            category: "Funny",
            prompt: "Spin this portrait in a silly, lighthearted loop with bouncy cartoon motion.",
            colors: [.mint, .yellow]
        ),
        VideoTemplate(
            title: "Prank Flash",
            category: "Funny",
            prompt: "Create a quick comedic flash-cut video with playful jump motion and bright pops of light.",
            colors: [.yellow, .pink]
        ),
        VideoTemplate(
            title: "Giggle Loop",
            category: "Funny",
            prompt: "Make a cheerful looping video with exaggerated expressions and bouncy camera energy.",
            colors: [.orange, .pink]
        ),

        VideoTemplate(
            title: "Quiet Rain",
            category: "Sad",
            prompt: "Add a slow rainy-window mood with soft grey tones and a melancholic camera drift.",
            colors: [.gray, .indigo]
        ),
        VideoTemplate(
            title: "Fading Light",
            category: "Sad",
            prompt: "Create a slow fade from light to shadow with a wistful, quiet atmosphere.",
            colors: [.indigo, .gray]
        ),
        VideoTemplate(
            title: "Lonely Walk",
            category: "Sad",
            prompt: "Animate a slow, solitary camera drift with muted tones and a reflective mood.",
            colors: [.gray, .blue]
        ),
        VideoTemplate(
            title: "Grey Skies",
            category: "Sad",
            prompt: "Cover the scene in soft overcast light with gentle motion and a subdued color grade.",
            colors: [.gray, .indigo]
        ),

        VideoTemplate(
            title: "Viral Spin",
            category: "Trends",
            prompt: "Create a fast trending-style spin transition with punchy color and sharp motion.",
            colors: [.purple, .blue]
        ),
        VideoTemplate(
            title: "Glitch Wave",
            category: "Trends",
            prompt: "Add a glitchy digital wave effect over the photo with a fast trending beat drop feel.",
            colors: [.blue, .pink]
        ),
        VideoTemplate(
            title: "Retro Pulse",
            category: "Trends",
            prompt: "Animate the photo with a retro VHS pulse effect and nostalgic trending color grade.",
            colors: [.pink, .purple]
        ),
        VideoTemplate(
            title: "Neon Drift",
            category: "Trends",
            prompt: "Drift the camera through neon-lit reflections with a smooth trending cyberpunk feel.",
            colors: [.cyan, .purple]
        ),
        VideoTemplate(
            title: "Trend Setter",
            category: "Trends",
            prompt: "Create a bold, high-energy trending video with punchy transitions and vivid color.",
            colors: [.blue, .pink]
        ),

        VideoTemplate(
            title: "Studio Reveal",
            category: "Design",
            prompt: "Reveal the subject with a clean studio-style camera move and premium soft lighting.",
            colors: [.gray, .purple]
        ),
        VideoTemplate(
            title: "Clean Cut",
            category: "Design",
            prompt: "Create a minimal, sharply lit video with crisp edges and a confident, clean motion.",
            colors: [.mint, .gray]
        ),
        VideoTemplate(
            title: "Brand Glow",
            category: "Design",
            prompt: "Add a premium brand-style glow with soft reflections and a slow, polished reveal.",
            colors: [.purple, .blue]
        ),
        VideoTemplate(
            title: "Minimal Frame",
            category: "Design",
            prompt: "Frame the subject with clean minimal composition and subtle, elegant motion.",
            colors: [.gray, .mint]
        ),
        VideoTemplate(
            title: "Premium Shine",
            category: "Design",
            prompt: "Add a premium glossy shine with soft highlights and a slow, refined camera move.",
            colors: [.purple, .pink]
        )
    ]

    static func template(id: UUID) -> VideoTemplate? {
        templates.first { $0.id == id }
    }

    /// Categories present in the catalog, ordered per `categoryOrder` (unknown categories sort last).
    static var availableCategories: [String] {
        let present = Set(templates.map(\.category))
        let ordered = categoryOrder.filter(present.contains)
        let extra = present.subtracting(categoryOrder).sorted()
        return ordered + extra
    }

    static func templates(in category: String) -> [VideoTemplate] {
        templates.filter { $0.category == category }
    }
}
