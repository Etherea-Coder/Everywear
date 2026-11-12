type SuggestionItem = {
  id: string;
  name: string;
  category: string;
  imageUrl: string;
  slot: string;
};

type WardrobeItem = {
  id: string;
  name: string;
  category: string;
  imageUrl: string;
};

type SuggestionResponse = Record<string, unknown>;

const MAX_RESPONSE_CHARS = 6_000;
const MAX_TEXT_LENGTH = 500;
const ALLOWED_SLOTS = new Set(["top", "bottom", "shoes", "accessory"]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function boundedText(
  value: unknown,
  limit = MAX_TEXT_LENGTH,
): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.trim();
  return text.length > 0 ? text.slice(0, limit) : undefined;
}

function parseJsonObject(text: string): Record<string, unknown> | null {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) return null;
  try {
    const parsed: unknown = JSON.parse(match[0]);
    return isRecord(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

function buildWardrobeIndex(input: unknown): Map<string, WardrobeItem> {
  const byId = new Map<string, WardrobeItem>();
  if (!Array.isArray(input)) return byId;

  for (const value of input) {
    if (!isRecord(value)) continue;
    const id = boundedText(value.id, 200);
    const name = boundedText(value.name, 200);
    const category = boundedText(value.category, 100);
    if (!id || !name || !category) continue;
    byId.set(id, {
      id,
      name,
      category,
      imageUrl: boundedText(value.image_url, 2_000) ??
        boundedText(value.imageUrl, 2_000) ?? "",
    });
  }
  return byId;
}

function resolveWardrobeItem(
  candidate: unknown,
  wardrobeById: Map<string, WardrobeItem>,
): WardrobeItem | null {
  if (!isRecord(candidate)) return null;
  const id = boundedText(candidate.id, 200);
  if (id) return wardrobeById.get(id) ?? null;

  // Older/model responses sometimes omit IDs. Resolve only an unambiguous exact
  // name/category match; never pass through model-supplied image URLs.
  const name = boundedText(candidate.name, 200)?.toLocaleLowerCase();
  const category = boundedText(candidate.category, 100)?.toLocaleLowerCase();
  if (!name) return null;
  const matches = [...wardrobeById.values()].filter((item) =>
    item.name.toLocaleLowerCase() === name &&
    (!category || item.category.toLocaleLowerCase() === category)
  );
  return matches.length === 1 ? matches[0] : null;
}

function toSuggestionItem(
  candidate: unknown,
  slot: unknown,
  wardrobeById: Map<string, WardrobeItem>,
  isAnchor = false,
): SuggestionItem | null {
  const item = resolveWardrobeItem(candidate, wardrobeById);
  if (!item || typeof slot !== "string") return null;
  if (isAnchor ? slot !== "anchor" : !ALLOWED_SLOTS.has(slot)) return null;
  return { ...item, slot };
}

function failure(): SuggestionResponse {
  return { success: false, error: "No usable outfit suggestion was returned." };
}

// Model output is untrusted. Return only app fields backed by the supplied
// wardrobe, with canonical image references and no model-controlled status.
export function parseTodaySuggestion(
  rawText: unknown,
  rawWardrobe: unknown,
): SuggestionResponse {
  if (typeof rawText !== "string" || rawText.length > MAX_RESPONSE_CHARS) {
    return failure();
  }
  const parsed = parseJsonObject(rawText.trim());
  const wardrobeById = buildWardrobeIndex(rawWardrobe);
  if (!parsed || wardrobeById.size === 0) return failure();

  const anchor = toSuggestionItem(parsed.anchor, "anchor", wardrobeById, true);
  if (!anchor) return failure();

  const items: SuggestionItem[] = [];
  const seen = new Set([anchor.id]);
  if (Array.isArray(parsed.items)) {
    for (const candidate of parsed.items) {
      if (!isRecord(candidate)) continue;
      const item = toSuggestionItem(candidate, candidate.slot, wardrobeById);
      if (!item || seen.has(item.id)) continue;
      seen.add(item.id);
      items.push(item);
      if (items.length === 5) break;
    }
  }

  return {
    success: true,
    title: boundedText(parsed.title, 120) ?? "Today's Style Idea",
    description: boundedText(parsed.description) ?? "",
    styling_note: boundedText(parsed.styling_note) ?? "",
    anchor,
    items,
  };
}
