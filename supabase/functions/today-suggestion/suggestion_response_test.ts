import { parseTodaySuggestion } from "./suggestion_response.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }`,
    );
  }
}

const wardrobe = [
  {
    id: "shirt-1",
    name: "Blue shirt",
    category: "top",
    image_url: "wardrobe-images/user-1/shirt.jpg",
  },
  {
    id: "shoe-1",
    name: "Brown shoes",
    category: "shoes",
    image_url: "https://images.example.test/shoes.jpg",
  },
];

Deno.test("returns the existing suggestion fields with canonical wardrobe data", () => {
  assertEquals(
    parseTodaySuggestion(
      JSON.stringify({
        title: "A polished look",
        description: "A simple combination.",
        styling_note: "Roll the sleeves.",
        anchor: {
          id: "shirt-1",
          name: "Invented name",
          category: "fake",
          imageUrl: "https://attacker.example/image.jpg",
        },
        items: [{
          id: "shoe-1",
          name: "Wrong name",
          category: "fake",
          imageUrl: "https://attacker.example/other.jpg",
          slot: "shoes",
        }],
        success: false,
        admin: true,
      }),
      wardrobe,
    ),
    {
      success: true,
      title: "A polished look",
      description: "A simple combination.",
      styling_note: "Roll the sleeves.",
      anchor: {
        id: "shirt-1",
        name: "Blue shirt",
        category: "top",
        imageUrl: "wardrobe-images/user-1/shirt.jpg",
        slot: "anchor",
      },
      items: [{
        id: "shoe-1",
        name: "Brown shoes",
        category: "shoes",
        imageUrl: "https://images.example.test/shoes.jpg",
        slot: "shoes",
      }],
    },
  );
});

Deno.test("resolves legacy responses without IDs only on an exact unique match", () => {
  const response = parseTodaySuggestion(
    JSON.stringify({
      anchor: { name: "Blue shirt", category: "top" },
      items: [],
    }),
    wardrobe,
  );
  assertEquals((response.anchor as Record<string, unknown>).id, "shirt-1");
  assertEquals(
    parseTodaySuggestion(
      JSON.stringify({
        anchor: { name: "Unknown garment", category: "top" },
        items: [],
      }),
      wardrobe,
    ).success,
    false,
  );
});

Deno.test("drops unknown, duplicate and invalid-slot wardrobe items", () => {
  const result = parseTodaySuggestion(
    JSON.stringify({
      anchor: { id: "shirt-1" },
      items: [
        { id: "shirt-1", slot: "top" },
        { id: "not-owned", slot: "top" },
        { id: "shoe-1", slot: "weapon" },
        { id: "shoe-1", slot: "shoes" },
      ],
    }),
    wardrobe,
  );
  assertEquals((result.items as unknown[]).length, 1);
  assertEquals(
    (result.items as Array<Record<string, unknown>>)[0].id,
    "shoe-1",
  );
});

Deno.test("bounds model output and fails closed when no valid anchor exists", () => {
  const result = parseTodaySuggestion(
    JSON.stringify({
      anchor: { id: "shirt-1" },
      description: "x".repeat(1_000),
      items: [],
    }),
    wardrobe,
  );
  assertEquals((result.description as string).length, 500);
  assertEquals(parseTodaySuggestion("not JSON", wardrobe).success, false);
  assertEquals(parseTodaySuggestion("{}", wardrobe).success, false);
  assertEquals(
    parseTodaySuggestion("x".repeat(6_001), wardrobe).success,
    false,
  );
});
