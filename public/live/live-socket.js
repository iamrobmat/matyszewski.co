import { parseSlideMessage, websocketUrl } from "./live-core.js";

export class LiveSocket {
  constructor({ onSlide, onStatus }) {
    this.onSlide = onSlide;
    this.onStatus = onStatus;
    this.socket = null;
    this.retryTimer = null;
    this.retryDelay = 250;
    this.closed = false;
    this.pendingSlide = null;
  }

  connect() {
    if (this.closed) return;
    this.onStatus?.("connecting");
    const socket = new WebSocket(websocketUrl());
    this.socket = socket;

    socket.addEventListener("open", () => {
      this.retryDelay = 250;
      this.onStatus?.("connected");
      if (this.pendingSlide !== null) {
        socket.send(JSON.stringify({ type: "goto", n: this.pendingSlide }));
        this.pendingSlide = null;
      }
    });

    socket.addEventListener("message", (event) => {
      if (typeof event.data !== "string") return;
      const slide = parseSlideMessage(event.data);
      if (slide !== null) this.onSlide?.(slide);
    });

    socket.addEventListener("close", () => this.reconnect());
    socket.addEventListener("error", () => socket.close());
  }

  reconnect() {
    if (this.closed || this.retryTimer !== null) return;
    this.onStatus?.("disconnected");
    this.retryTimer = window.setTimeout(() => {
      this.retryTimer = null;
      this.connect();
    }, this.retryDelay);
    this.retryDelay = Math.min(this.retryDelay * 2, 5_000);
  }

  sendGoto(slide) {
    if (this.socket?.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({ type: "goto", n: slide }));
    } else {
      this.pendingSlide = slide;
    }
  }

  close() {
    this.closed = true;
    if (this.retryTimer !== null) window.clearTimeout(this.retryTimer);
    this.socket?.close(1000, "Page closed");
  }
}
