// This is the existing backend colour vocabulary formerly kept in
// generate-ai-insights. Keep its English values canonical for storage and
// analytics; aliases only normalize legacy/localized text into these values.
export const COLOR_VOCABULARY = [
  "black",
  "white",
  "gray",
  "grey",
  "brown",
  "beige",
  "cream",
  "navy",
  "blue",
  "red",
  "green",
  "yellow",
  "orange",
  "pink",
  "purple",
  "burgundy",
  "camel",
  "khaki",
  "olive",
  "coral",
  "teal",
  "gold",
  "silver",
  "tan",
] as const;

// Grey is an English spelling alias of the existing `gray` value. The
// canonical output list is derived from the vocabulary above.
export const CANONICAL_COLOR_VALUES = COLOR_VOCABULARY.filter((color) =>
  color !== "grey"
);

const LEGACY_COLOR_ALIASES: Record<string, readonly string[]> = {
  black: ["noir", "noire", "negro", "negra"],
  white: ["blanc", "blanche", "blanco", "blanca"],
  gray: ["grey", "gris", "grise", "grises"],
  brown: ["marron", "brun", "brune", "castano", "castana"],
  beige: ["beis"],
  cream: ["creme", "crema"],
  navy: ["bleu marine", "azul marino", "navy blue"],
  blue: ["bleu", "azul"],
  red: ["rouge", "rojo", "roja"],
  green: ["vert", "verte", "verde"],
  yellow: ["jaune", "amarillo", "amarilla"],
  orange: ["naranja"],
  pink: ["rose", "rosa"],
  purple: ["violet", "violette", "violeta", "morado", "morada"],
  burgundy: ["bordeaux", "burdeos", "granate"],
  khaki: ["kaki", "caqui"],
  olive: ["oliva"],
  coral: ["corail"],
  teal: ["bleu canard", "verde azulado"],
  gold: ["or", "dore", "dorado", "dorada"],
  silver: ["argent", "plateado", "plateada"],
  tan: ["brun clair", "canela", "tostado", "tostada"],
};

function foldWords(value: string): string[] {
  return value
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .match(/\p{L}+/gu) ?? [];
}

type Alias = { value: string; words: string[]; order: number };

const aliases: Alias[] = CANONICAL_COLOR_VALUES.flatMap((color, order) => {
  const values = [color, ...(LEGACY_COLOR_ALIASES[color] ?? [])];
  return values.map((value) => ({
    value: color,
    words: foldWords(value),
    order,
  }));
}).sort((left, right) =>
  right.words.length - left.words.length || right.words.join(" ").length -
    left.words.join(" ").length ||
  left.order - right.order
);

function findColor(
  value: string,
  storedSemanticLabel = false,
): { color: string; start: number } | null {
  const words = foldWords(value);
  let best:
    | { color: string; start: number; length: number; order: number }
    | null = null;
  for (const alias of aliases) {
    // "or" is a legacy French gold label, but also an English conjunction.
    // Accept it only while reading persisted semantic labels.
    if (
      !storedSemanticLabel && alias.value === "gold" &&
      alias.words.length === 1 && alias.words[0] === "or"
    ) continue;
    for (let start = 0; start <= words.length - alias.words.length; start++) {
      if (!alias.words.every((word, index) => words[start + index] === word)) {
        continue;
      }
      if (
        best === null || start < best.start ||
        (start === best.start && alias.words.length > best.length) ||
        (start === best.start && alias.words.length === best.length &&
          alias.order < best.order)
      ) {
        best = {
          color: alias.value,
          start,
          length: alias.words.length,
          order: alias.order,
        };
      }
    }
  }
  return best ? { color: best.color, start: best.start } : null;
}

/** Maps canonical or legacy English/French/Spanish text to the backend value. */
export function normalizeCanonicalColor(value: string): string | null {
  return findColor(value)?.color ?? null;
}

/** Extracts one color from an old semantic_label without substring matches. */
export function extractCanonicalColor(label: string): string | null {
  return findColor(label, true)?.color ?? null;
}

export type DominantColorAnalytics = {
  dominantColors: string[];
  colorPercentages: number[];
  colorCounts: Record<string, number>;
};

/** Counts each item once using canonical values; display localization is a UI concern. */
export function calculateDominantColorAnalytics(
  labels: readonly (string | null | undefined)[],
  limit = 4,
): DominantColorAnalytics {
  const colorCounts: Record<string, number> = {};
  for (const label of labels) {
    const color = label ? extractCanonicalColor(label) : null;
    if (color) colorCounts[color] = (colorCounts[color] ?? 0) + 1;
  }
  const sorted = Object.entries(colorCounts)
    .sort(([, left], [, right]) => right - left)
    .slice(0, Math.max(0, limit));
  return {
    dominantColors: sorted.map(([color]) =>
      color.charAt(0).toUpperCase() + color.slice(1)
    ),
    colorPercentages: sorted.map(([, count]) =>
      Math.round((count / Math.max(labels.length, 1)) * 100)
    ),
    colorCounts,
  };
}
