import { DEFAULT_SLIDE, parseGotoMessage, slideMessage } from "./protocol";

interface Env {
  ASSETS: Fetcher;
  SESSION: DurableObjectNamespace;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/live/ws") {
      if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
        return new Response("WebSocket upgrade required", { status: 426 });
      }

      const session = env.SESSION.get(env.SESSION.idFromName("live"));
      return session.fetch(request);
    }

    return env.ASSETS.fetch(request);
  },
};

export class Session implements DurableObject {
  private readonly ctx: DurableObjectState;
  private currentSlide = DEFAULT_SLIDE;

  constructor(ctx: DurableObjectState) {
    this.ctx = ctx;
    ctx.blockConcurrencyWhile(async () => {
      this.currentSlide =
        (await ctx.storage.get<number>("current_slide")) ?? DEFAULT_SLIDE;
    });
  }

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("WebSocket upgrade required", { status: 426 });
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    server.send(slideMessage(this.currentSlide));

    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(_socket: WebSocket, message: string | ArrayBuffer): Promise<void> {
    if (typeof message !== "string") return;

    const nextSlide = parseGotoMessage(message);
    if (nextSlide === null) return;

    this.currentSlide = nextSlide;
    await this.ctx.storage.put("current_slide", nextSlide);

    const update = slideMessage(nextSlide);
    for (const socket of this.ctx.getWebSockets()) {
      try {
        socket.send(update);
      } catch {
        // A disconnected peer must not prevent delivery to healthy peers.
      }
    }
  }

  webSocketClose(): void {
    // Cloudflare removes closed sockets from getWebSockets() automatically.
  }

  webSocketError(): void {
    // A failed peer must not affect the remaining session.
  }
}
