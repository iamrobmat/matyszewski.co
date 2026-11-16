export const FIRST_SLIDE = 1;

export function clampSlide(value, totalSlides) {
  const total = Number.isInteger(totalSlides) && totalSlides >= FIRST_SLIDE ? totalSlides : FIRST_SLIDE;
  const parsed = Number(value);
  const slide = Number.isFinite(parsed) ? Math.trunc(parsed) : FIRST_SLIDE;
  return Math.min(total, Math.max(FIRST_SLIDE, slide));
}

export function nextPreviewSlide(current, totalSlides) {
  return clampSlide(current + 1, totalSlides);
}

const NEXT_KEYS = new Set(["PageDown", "ArrowRight", "ArrowDown", " "]);
const PREVIOUS_KEYS = new Set(["PageUp", "ArrowLeft", "ArrowUp"]);

export function directionForKey(key) {
  if (NEXT_KEYS.has(key)) return 1;
  if (PREVIOUS_KEYS.has(key)) return -1;
  return 0;
}

export function parseSlideMessage(value) {
  try {
    const message = JSON.parse(value);
    if (message?.type !== "slide" || !Number.isInteger(message.n) || message.n < FIRST_SLIDE) {
      return null;
    }
    return message.n;
  } catch {
    return null;
  }
}

export function websocketUrl(locationLike = window.location) {
  const protocol = locationLike.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${locationLike.host}/live/ws`;
}
