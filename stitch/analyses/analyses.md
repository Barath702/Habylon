# Design System Strategy: Neon-Glass Editorial

## 1. Overview & Creative North Star
**Creative North Star: "The Luminescent Pulse"**

This design system is engineered to transform habit tracking from a chore into a high-end digital ritual. It rejects the clinical "white-label" look of standard productivity apps in favor of a dark, editorial aesthetic that feels both private and prestigious. By utilizing **Glassmorphism** and **chromatic luminescence**, we create a UI that doesn't just display data but "glows" with the user's progress.

The interface moves away from rigid, boxed-in grids. Instead, it uses **tonal depth and overlapping translucency** to suggest a continuous, living space. Information is organized through physical hierarchy—nested layers of "frosted glass" that catch light from neon accents, creating a signature depth that feels premium and intentional.

---

## 2. Colors & Surface Architecture

### The Palette
The core of the system is a **pure-black base (`#0e0e0e`)**, which allows neon accents to pop with maximum vibrance. 
- **Primary (Neon Purple):** `#bc9eff` – Used for fitness, spirit, and high-energy habits.
- **Secondary (Neon Green):** `#52fd98` – Used for health, productivity, and "growth" habits.
- **Tertiary (Neon Orange):** `#ffb37f` – Used for nutrition and social habits.

### The "No-Line" Rule
Traditional 1px borders are strictly prohibited for sectioning. Structural definition must be achieved through:
1.  **Surface Shifts:** Placing a `surface-container-low` component on a `surface` background.
2.  **Tonal Transitions:** Using subtle gradients between `surface-variant` and `surface-container`.
3.  **Luminescent Shadows:** Using the color of the habit category (e.g., Purple `primary`) as a soft 4-8% opacity glow rather than a grey shadow.

### Glass & Gradient Execution
Floating elements (modals, top-level cards) must utilize **Glassmorphism**. 
- **Recipe:** `surface-container` color at 70% opacity + 20px Backdrop Blur + a 0.5px "Ghost Border" using `outline-variant` at 15% opacity.
- **CTA Soul:** Main buttons should never be flat. Use a linear gradient from `primary` to `primary-container` to provide a sense of volume.

---

## 3. Typography: Editorial Sophistication

The system employs a dual-font strategy to balance character with readability.

*   **Headlines & Body (Manrope):** A modern, geometric sans-serif. Used for its clean legibility and wide apertures.
    *   **Headline-LG (2rem):** Used for date headers and primary habit titles.
    *   **Body-MD (0.875rem):** The workhorse for streak counts and descriptions.
*   **Labels & Functional Text (Space Grotesk):** A high-character, monospaced-leaning font.
    *   **Label-MD (0.75rem):** Used for heatmap axes, chip labels, and "Ghost" buttons. This provides an "engineered" editorial feel that distinguishes data from content.

---

## 4. Elevation & Depth: The Layering Principle

Depth is not simulated with shadows; it is constructed through **Tonal Layering**.

1.  **Level 0 (Base):** `surface` (#0e0e0e) – The infinite void.
2.  **Level 1 (Sections):** `surface-container-low` – Used for large layout blocks or background containers.
3.  **Level 2 (Cards):** `surface-container-highest` – Used for individual habit cards.
4.  **Level 3 (Interactive):** `surface-bright` – Used for active states and floating toggles.

### Ambient Shadows (The "Glow")
When a card is active or "in progress," replace the traditional shadow with a **Category Glow**. 
- **Shadow Token:** `X: 0, Y: 10, Blur: 30, Spread: -5`. 
- **Color:** Use the accent color (`primary`, `secondary`, or `tertiary`) at 12% opacity. This makes the card appear as if it is sitting on a light-emitting surface.

---

## 5. Components

### Roundedness Scale
- **Containers/Cards:** `xl` (1.5rem / 24dp) to create a soft, friendly silhouette.
- **Interactive Elements (Buttons/Chips):** `full` (9999px) for a tactile, pill-shaped feel.

### Heatmap Grids
The signature component of the app. 
- **Inactive States:** `surface-variant` at 40% opacity.
- **Active States:** Solid `primary`, `secondary`, or `tertiary`. 
- **Visual Rule:** No dividers. Use `spacing-0.5` (2px) to separate squares. This creates a "mosaic" feel.

### Category Chips
- **Style:** Ghost style. No fill. 
- **Border:** 1px `outline-variant` at 30% opacity. 
- **Active State:** Fill with accent color at 15% opacity and change text to solid accent color.

### Interactive Toggles & Buttons
- **Primary Button:** High-contrast `on-primary` text on a `primary` to `primary-container` gradient.
- **Glowing Toggles:** When 'On', the toggle track should emit a subtle `secondary` (green) glow.
- **Input Fields:** Use `surface-container-highest` with no border. On focus, apply a 1px `primary` ghost border at 50% opacity.

---

## 6. Do's and Don'ts

### Do:
- **Use Asymmetry:** Place the habit name and streak count on the left, but keep the "Check" action floating on the right to create a sophisticated editorial balance.
- **Embrace Negative Space:** Use `spacing-10` (40dp) between major card sections to let the glass elements "breathe."
- **Nesting:** Always place a lighter container inside a darker one to signify "drilling down" into details.

### Don't:
- **Never use Pure White text (#FFFFFF) for everything:** Use `on-surface-variant` (#adaaaa) for secondary information to maintain high-end tonal hierarchy.
- **Avoid 100% Opaque Borders:** This shatters the "glass" illusion. If a boundary is needed, use a 10-20% opacity ghost border.
- **No Traditional Shadows:** Never use black or dark grey shadows on a dark background; they are invisible and add "mud" to the design. Use light-emitting glows instead.

---

## 7. Interaction Pattern: The "Pulse"
When a user completes a habit, the card should briefly expand (Scale 1.02) and trigger a radial gradient pulse originating from the checkmark, momentarily washing the card in the category's accent color before settling back into its glass state.