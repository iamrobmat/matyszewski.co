import { clampSlide, nextPreviewSlide } from "../live-core.js";

export class PresenterController {
  constructor({ totalSlides, initialSlide = 1, onRender, onGoto }) {
    this.totalSlides = Math.max(1, Math.trunc(totalSlides));
    this.currentSlide = clampSlide(initialSlide, this.totalSlides);
    this.onRender = onRender;
    this.onGoto = onGoto;
    this.render();
  }

  render() {
    this.onRender({
      current: this.currentSlide,
      next: nextPreviewSlide(this.currentSlide, this.totalSlides),
      total: this.totalSlides,
    });
  }

  sync(value) {
    const slide = clampSlide(value, this.totalSlides);
    if (slide === this.currentSlide) return false;
    this.currentSlide = slide;
    this.render();
    return true;
  }

  move(direction) {
    const slide = clampSlide(this.currentSlide + direction, this.totalSlides);
    if (slide === this.currentSlide) return false;
    this.currentSlide = slide;
    this.render();
    this.onGoto(slide);
    return true;
  }
}
