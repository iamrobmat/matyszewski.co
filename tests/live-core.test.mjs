import test from "node:test";
import assert from "node:assert/strict";
import {
  clampSlide,
  directionForKey,
  nextPreviewSlide,
  parseSlideMessage,
  websocketUrl,
} from "../public/live/live-core.js";
import { parseGotoMessage, slideMessage } from "../src/protocol.ts";
import { PresenterController } from "../public/live/present/presenter-controller.js";

test("clampSlide ogranicza numer do zakresu prezentacji", () => {
  assert.equal(clampSlide(-5, 70), 1);
  assert.equal(clampSlide(25, 70), 25);
  assert.equal(clampSlide(999, 70), 70);
});

test("podgląd następnego slajdu nie wychodzi poza zakres", () => {
  assert.equal(nextPreviewSlide(24, 70), 25);
  assert.equal(nextPreviewSlide(70, 70), 70);
});

test("mapowanie klawiszy obejmuje wymagane wejścia i ignoruje pozostałe", () => {
  for (const key of ["PageDown", "ArrowRight", "ArrowDown", " "]) assert.equal(directionForKey(key), 1);
  for (const key of ["PageUp", "ArrowLeft", "ArrowUp"]) assert.equal(directionForKey(key), -1);
  for (const key of ["Enter", "Escape", "a"]) assert.equal(directionForKey(key), 0);
});

test("protokół akceptuje tylko poprawne goto", () => {
  assert.equal(parseGotoMessage('{"type":"goto","n":25}'), 25);
  for (const message of ["{", "null", "{}", '{"type":"slide","n":2}', '{"type":"goto","n":0}', '{"type":"goto","n":2.5}', '{"type":"goto","n":"2"}']) {
    assert.equal(parseGotoMessage(message), null);
  }
});

test("wiadomości slide i adres WebSocket mają oczekiwany format", () => {
  assert.equal(slideMessage(7), '{"type":"slide","n":7}');
  assert.equal(parseSlideMessage('{"type":"slide","n":7}'), 7);
  assert.equal(parseSlideMessage('{"type":"goto","n":7}'), null);
  assert.equal(websocketUrl({ protocol: "https:", host: "matyszewski.co" }), "wss://matyszewski.co/live/ws");
});

test("jedna akcja prezentera powoduje jeden render i jeden goto", () => {
  const renders = [];
  const gotos = [];
  const controller = new PresenterController({
    totalSlides: 70,
    initialSlide: 25,
    onRender(state) { renders.push(state); },
    onGoto(slide) { gotos.push(slide); },
  });

  assert.deepEqual(renders, [{ current: 25, next: 26, total: 70 }]);
  assert.equal(controller.move(1), true);
  assert.deepEqual(renders.at(-1), { current: 26, next: 27, total: 70 });
  assert.deepEqual(gotos, [26]);

  assert.equal(controller.sync(40), true);
  assert.deepEqual(gotos, [26], "stan z Durable Object nie może wysłać goto ponownie");

  controller.sync(70);
  assert.equal(controller.move(1), false);
  assert.deepEqual(renders.at(-1), { current: 70, next: 70, total: 70 });
  assert.deepEqual(gotos, [26], "akcja na granicy zakresu nie może wysłać goto");
});
