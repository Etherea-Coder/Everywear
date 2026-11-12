import { parseCoachResponse } from "./coach_response.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }`,
    );
  }
}

Deno.test("returns bounded passive advice as the existing tip contract", () => {
  const result = parseCoachResponse("passive", "  Try a new layer.  ");
  assertEquals(result, {
    success: true,
    mode: "passive",
    tip: "Try a new layer.",
  });
});

Deno.test("keeps active coach fields and ignores model control fields", () => {
  assertEquals(
    parseCoachResponse(
      "active",
      JSON.stringify({
        success: false,
        mode: "event",
        answer: "Pair the jacket with dark denim.",
        next_step: "Try it tomorrow.",
        raw: "unnecessary provider text",
        admin: true,
      }),
    ),
    {
      success: true,
      mode: "active",
      answer: "Pair the jacket with dark denim.",
      next_step: "Try it tomorrow.",
    },
  );
});

Deno.test("keeps only expected event coaching fields", () => {
  assertEquals(
    parseCoachResponse(
      "event",
      JSON.stringify({
        intro: "Choose a polished layer.",
        outfit_1: "Blazer and trousers.",
        outfit_2: "",
        prep_tip: "Check the forecast.",
        arbitrary: "discarded",
      }),
    ),
    {
      success: true,
      mode: "event",
      intro: "Choose a polished layer.",
      outfit_1: "Blazer and trousers.",
      prep_tip: "Check the forecast.",
    },
  );
});

Deno.test("bounds fields and fails closed for malformed or incomplete output", () => {
  const longText = "x".repeat(2_000);
  assertEquals(
    (parseCoachResponse("active", JSON.stringify({ answer: longText }))
      .answer as string).length,
    1_200,
  );
  assertEquals(parseCoachResponse("active", "not JSON").success, false);
  assertEquals(
    parseCoachResponse("event", JSON.stringify({ intro: "Missing outfits" }))
      .success,
    false,
  );
  assertEquals(parseCoachResponse("unknown", "text").success, false);
  assertEquals(parseCoachResponse("passive", "x".repeat(4_001)).success, false);
});
