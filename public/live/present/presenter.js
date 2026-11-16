import { DeckAdapter } from "../deck-adapter.js";
import { directionForKey } from "../live-core.js";
import { LiveSocket } from "../live-socket.js";
import { PresenterController } from "./presenter-controller.js";

const currentAdapter = new DeckAdapter(document.querySelector("#current-deck"));
const nextAdapter = new DeckAdapter(document.querySelector("#next-deck"));
const currentNumber = document.querySelector("#current-number");
const nextNumber = document.querySelector("#next-number");
const previousButton = document.querySelector("#previous");
const nextButton = document.querySelector("#next");
const inputLayer = document.querySelector("#input-layer");
const connection = document.querySelector("#connection");
const error = document.querySelector("#error");

let socket;
let controller;

function setConnection(state) {
  connection.dataset.state = state;
  connection.textContent = state === "connected" ? "Połączono" : state === "connecting" ? "Łączenie" : "Ponawiam";
}

function isEditableTarget(target) {
  return target instanceof HTMLElement &&
    (target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName));
}

try {
  const counts = await Promise.all([currentAdapter.ready(), nextAdapter.ready()]);
  if (counts[0] !== counts[1]) throw new Error("Podglądy mają różną liczbę slajdów.");

  socket = new LiveSocket({
    onStatus: setConnection,
    onSlide(slide) { controller.sync(slide); },
  });
  controller = new PresenterController({
    totalSlides: counts[0],
    onGoto(slide) { socket.sendGoto(slide); },
    onRender({ current, next, total }) {
      currentAdapter.setSlide(current);
      nextAdapter.setSlide(next);
      currentNumber.textContent = `${current} / ${total}`;
      nextNumber.textContent = `${next} / ${total}`;
      previousButton.disabled = current <= 1;
      nextButton.disabled = current >= total;
    },
  });
  socket.connect();
  window.addEventListener("pagehide", () => socket.close(), { once: true });

  window.addEventListener("keydown", (event) => {
    if (event.repeat || isEditableTarget(event.target)) return;
    const direction = directionForKey(event.key);
    if (direction === 0) return;
    event.preventDefault();
    controller.move(direction);
  });

  inputLayer.addEventListener("click", (event) => {
    if (event.button === 0) controller.move(1);
  });
  previousButton.addEventListener("click", () => controller.move(-1));
  nextButton.addEventListener("click", () => controller.move(1));
} catch (reason) {
  error.hidden = false;
  error.textContent = reason instanceof Error ? reason.message : "Nie udało się uruchomić widoku prezentera.";
}
