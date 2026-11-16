import { clampSlide, FIRST_SLIDE } from "./live-core.js";

export class DeckAdapter {
  constructor(frame) {
    this.frame = frame;
    this.totalSlides = FIRST_SLIDE;
  }

  async ready() {
    const existingSlides = this.frame.contentDocument?.querySelectorAll(".deck-slide").length ?? 0;
    if (existingSlides < FIRST_SLIDE) {
      await new Promise((resolve, reject) => {
        this.frame.addEventListener("load", resolve, { once: true });
        this.frame.addEventListener("error", () => reject(new Error("Nie udało się wczytać prezentacji.")), {
          once: true,
        });
      });
    }

    const slides = this.frame.contentDocument?.querySelectorAll(".deck-slide").length ?? 0;
    if (slides < FIRST_SLIDE) throw new Error("Prezentacja nie zawiera elementów .deck-slide.");
    this.totalSlides = slides;
    return slides;
  }

  getSlide() {
    const hash = this.frame.contentWindow?.location.hash.replace(/^#/, "") ?? "";
    return clampSlide(Number.parseInt(hash, 10), this.totalSlides);
  }

  setSlide(value) {
    const slide = clampSlide(value, this.totalSlides);
    if (this.frame.contentWindow && this.frame.contentWindow.location.hash !== `#${slide}`) {
      this.frame.contentWindow.location.hash = `#${slide}`;
    }
    return slide;
  }
}
