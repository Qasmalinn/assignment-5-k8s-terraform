import { hostname } from "os";

const port = process.env.PORT || 3000;
const host = hostname();

const server = Bun.serve({
  port,
  fetch(req) {
    const url = new URL(req.url);

    if (url.pathname === "/") {
      return new Response(
        `Kubernetes deployment is up and running!\nHostname: ${host}\nTime: ${new Date().toISOString()}\n`
      );
    }

    if (url.pathname === "/health") {
      return Response.json({
        status: "ok",
        hostname: host,
        timestamp: new Date().toISOString(),
      });
    }

    return new Response("Not Found", { status: 404 });
  },
});

console.log(`Server running at http://localhost:${server.port}`);
