export const DEFAULT_SLIDE = 1;
export const MAX_PROTOCOL_SLIDE = 10_000;

export function parseGotoMessage(value: string): number | null {
  let message: unknown;

  try {
    message = JSON.parse(value);
  } catch {
    return null;
  }

  if (
    typeof message !== "object" ||
    message === null ||
    !("type" in message) ||
    !("n" in message)
  ) {
    return null;
  }

  const candidate = message as { type: unknown; n: unknown };
  if (
    candidate.type !== "goto" ||
    !Number.isInteger(candidate.n) ||
    (candidate.n as number) < DEFAULT_SLIDE ||
    (candidate.n as number) > MAX_PROTOCOL_SLIDE
  ) {
    return null;
  }

  return candidate.n as number;
}

export function slideMessage(n: number): string {
  return JSON.stringify({ type: "slide", n });
}
