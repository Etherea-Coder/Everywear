import {
  calculateDominantColorAnalytics,
  extractCanonicalColor,
  normalizeCanonicalColor,
} from "./color_vocabulary.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }`,
    );
  }
}

Deno.test("English, French, and Spanish labels produce identical analytics", () => {
  const equivalentInventories = [
    [
      "Blue cotton top",
      "Navy wool coat",
      "Black linen dress",
      "Blue denim jeans",
    ],
    [
      "Haut coton bleu",
      "Manteau laine bleu marine",
      "Robe lin noire",
      "Jean denim bleu",
    ],
    [
      "Top algodón azul",
      "Abrigo lana azul marino",
      "Vestido lino negro",
      "Vaquero denim azul",
    ],
  ];

  const results = equivalentInventories.map((labels) =>
    calculateDominantColorAnalytics(labels)
  );
  for (const result of results.slice(1)) {
    assertEquals(result, results[0]);
  }
  assertEquals(results[0], {
    dominantColors: ["Blue", "Navy", "Black"],
    colorPercentages: [50, 25, 25],
    colorCounts: { blue: 2, navy: 1, black: 1 },
  });
});

Deno.test("mixed-language legacy labels normalize once and safely", () => {
  const labels = [
    "Top / bleu / algodón",
    "T-shirt / blue / coton",
    "Abrigo azul marino / wool",
    "Robe / noir / linen",
  ];
  assertEquals(calculateDominantColorAnalytics(labels), {
    dominantColors: ["Blue", "Navy", "Black"],
    colorPercentages: [50, 25, 25],
    colorCounts: { blue: 2, navy: 1, black: 1 },
  });
  assertEquals(extractCanonicalColor("A blueberry print shirt"), null);
  assertEquals(normalizeCanonicalColor("gris / grey"), "gray");
});
