import { DeckAdapter } from "./deck-adapter.js";
import { clampSlide } from "./live-core.js";
import { LiveSocket } from "./live-socket.js";

const frame = document.querySelector("#deck");
const previousButton = document.querySelector("#previous");
const nextButton = document.querySelector("#next");
const followButton = document.querySelector("#follow");
const slideNumber = document.querySelector("#slide-number");
const connection = document.querySelector("#connection");
const error = document.querySelector("#error");

const adapter = new DeckAdapter(frame);
let liveSlide = 1;
let visibleSlide = 1;
let furthestShownSlide = 1;
let following = true;

function render() {
  visibleSlide = adapter.getSlide();
  slideNumber.textContent = `${visibleSlide} / ${adapter.totalSlides}`;
  followButton.hidden = following;
  previousButton.disabled = visibleSlide <= 1;
  nextButton.disabled = visibleSlide >= furthestShownSlide;
}

function showLocalSlide(value) {
  following = false;
  adapter.setSlide(clampSlide(Math.min(value, furthestShownSlide), adapter.totalSlides));
  render();
}

function setConnection(state) {
  connection.dataset.state = state;
  connection.textContent = state === "connected" ? "Na żywo" : state === "connecting" ? "Łączenie" : "Ponawiam";
}

try {
  await adapter.ready();
  render();

  const socket = new LiveSocket({
    onStatus: setConnection,
    onSlide(slide) {
      liveSlide = clampSlide(slide, adapter.totalSlides);
      furthestShownSlide = Math.max(furthestShownSlide, liveSlide);
      if (following) adapter.setSlide(liveSlide);
      render();
    },
  });
  socket.connect();
  window.addEventListener("pagehide", () => socket.close(), { once: true });

  previousButton.addEventListener("click", () => showLocalSlide(visibleSlide - 1));
  nextButton.addEventListener("click", () => showLocalSlide(visibleSlide + 1));
  followButton.addEventListener("click", () => {
    following = true;
    adapter.setSlide(liveSlide);
    render();
  });

  window.setInterval(() => {
    const observed = adapter.getSlide();
    if (observed !== visibleSlide) {
      if (observed > furthestShownSlide) {
        adapter.setSlide(visibleSlide);
      } else {
        following = observed === liveSlide ? following : false;
        visibleSlide = observed;
      }
      render();
    }
  }, 200);
} catch (reason) {
  error.hidden = false;
  error.textContent = reason instanceof Error ? reason.message : "Nie udało się uruchomić prezentacji.";
}
