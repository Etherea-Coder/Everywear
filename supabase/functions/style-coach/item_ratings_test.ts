import { selectTopRatedItems } from "./item_ratings.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`Expected ${expectedJson}, received ${actualJson}`);
  }
}

Deno.test("selects valid ratings with at least two rated outfits", () => {
  assertEquals(
    selectTopRatedItems({
      jacket: { avg_rating: 4.5, rated_count: 3 },
      shoes: { avg_rating: 5, rated_count: 1 },
      hat: { avg_rating: 3, rated_count: 2 },
    }),
    [
      { id: "jacket", avg_rating: 4.5, rated_count: 3 },
      { id: "hat", avg_rating: 3, rated_count: 2 },
    ],
  );
});

Deno.test("rejects null, non-finite, out-of-range and unsafe rating data", () => {
  assertEquals(
    selectTopRatedItems({
      nullValue: null,
      nullRating: { avg_rating: null, rated_count: 3 },
      nanRating: { avg_rating: Number.NaN, rated_count: 3 },
      lowRating: { avg_rating: 0, rated_count: 3 },
      highRating: { avg_rating: 6, rated_count: 3 },
      fractionalCount: { avg_rating: 4, rated_count: 2.5 },
      hugeCount: { avg_rating: 4, rated_count: Number.MAX_SAFE_INTEGER + 1 },
    }),
    [],
  );
});

Deno.test("caps and orders the model-facing rating list", () => {
  const averages = [3, 4, 5, 1, 2, 4.5, 4.2];
  const ratings = Object.fromEntries(
    averages.map((average, index) => [
      `item-${index}`,
      { avg_rating: average, rated_count: 2 },
    ]),
  );
  assertEquals(
    selectTopRatedItems(ratings).map(({ id }) => id),
    ["item-2", "item-5", "item-6", "item-1", "item-0"],
  );
});
