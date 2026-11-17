export type ResponseLocale = "en" | "fr" | "es";

export function normalizeResponseLocale(value: unknown): ResponseLocale {
  const code = typeof value === "string"
    ? value.trim().toLowerCase().split(/[-_]/, 1)[0]
    : "";
  return code === "fr" || code === "es" ? code : "en";
}

export function responseLanguageName(locale: ResponseLocale): string {
  switch (locale) {
    case "fr":
      return "French";
    case "es":
      return "Spanish";
    default:
      return "English";
  }
}
