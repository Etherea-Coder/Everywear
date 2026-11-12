type ItemRating = {
  id: string;
  avg_rating: number;
  rated_count: number;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function selectTopRatedItems(value: unknown): ItemRating[] {
  if (!isRecord(value)) return [];

  return Object.entries(value)
    .flatMap(([id, rawRating]) => {
      if (!id.trim() || !isRecord(rawRating)) return [];
      const { avg_rating: average, rated_count: count } = rawRating;
      if (
        typeof average !== "number" || !Number.isFinite(average) ||
        average < 1 || average > 5 ||
        typeof count !== "number" || !Number.isSafeInteger(count) ||
        count < 2 || count > 1_000_000
      ) return [];
      return [{ id, avg_rating: average, rated_count: count }];
    })
    .sort((a, b) => b.avg_rating - a.avg_rating)
    .slice(0, 5);
}
