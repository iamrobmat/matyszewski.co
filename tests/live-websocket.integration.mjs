import test from "node:test";
import assert from "node:assert/strict";

const baseUrl = process.env.LIVE_BASE_URL ?? "http://127.0.0.1:8787";
const websocketEndpoint = new URL("/live/ws", baseUrl);
websocketEndpoint.protocol = websocketEndpoint.protocol === "https:" ? "wss:" : "ws:";

function openClient() {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(websocketEndpoint);
    const timer = setTimeout(() => reject(new Error("Timeout while opening WebSocket")), 3_000);
    socket.addEventListener("message", (event) => {
      clearTimeout(timer);
      resolve({ socket, initial: JSON.parse(event.data) });
    }, { once: true });
    socket.addEventListener("error", reject, { once: true });
  });
}

function nextSlide(socket, expected) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timeout waiting for slide ${expected}`)), 3_000);
    const handler = (event) => {
      const message = JSON.parse(event.data);
      if (message.type !== "slide" || message.n !== expected) return;
      clearTimeout(timer);
      socket.removeEventListener("message", handler);
      resolve(message);
    };
    socket.addEventListener("message", handler);
  });
}

function expectNoMessage(socket, timeout = 150) {
  return new Promise((resolve, reject) => {
    const handler = (event) => {
      clearTimeout(timer);
      reject(new Error(`Unexpected duplicate message: ${event.data}`));
    };
    const timer = setTimeout(() => {
      socket.removeEventListener("message", handler);
      resolve();
    }, timeout);
    socket.addEventListener("message", handler);
  });
}

test("Durable Object synchronizuje wielu klientów i odtwarza stan", async () => {
  const presenter = await openClient();
  const participantA = await openClient();
  const participantB = await openClient();
  const target = presenter.initial.n === 25 ? 26 : 25;

  const updates = [
    nextSlide(presenter.socket, target),
    nextSlide(participantA.socket, target),
    nextSlide(participantB.socket, target),
  ];
  const startedAt = performance.now();
  presenter.socket.send(JSON.stringify({ type: "goto", n: target }));
  await Promise.all(updates);
  assert.ok(performance.now() - startedAt < 1_000, "broadcast should arrive in under one second");
  await expectNoMessage(participantA.socket);

  presenter.socket.send("not-json");
  presenter.socket.send(JSON.stringify({ type: "goto", n: 0 }));
  const survivorTarget = target + 1;
  const survivor = nextSlide(participantA.socket, survivorTarget);
  presenter.socket.send(JSON.stringify({ type: "goto", n: survivorTarget }));
  await survivor;

  participantB.socket.close();
  const newcomer = await openClient();
  assert.deepEqual(newcomer.initial, { type: "slide", n: survivorTarget });

  for (const socket of [presenter.socket, participantA.socket, newcomer.socket]) socket.close();
});

test("sesja obsługuje prezentera i 20 uczestników poniżej jednej sekundy", async () => {
  const clients = await Promise.all(Array.from({ length: 21 }, () => openClient()));
  const target = clients[0].initial.n === 50 ? 51 : 50;
  const updates = clients.map(({ socket }) => nextSlide(socket, target));
  const startedAt = performance.now();
  clients[0].socket.send(JSON.stringify({ type: "goto", n: target }));
  await Promise.all(updates);
  const elapsed = performance.now() - startedAt;

  assert.ok(elapsed < 1_000, `21 clients received the update in ${elapsed.toFixed(1)} ms`);
  await expectNoMessage(clients.at(-1).socket);
  for (const { socket } of clients) socket.close();
});
