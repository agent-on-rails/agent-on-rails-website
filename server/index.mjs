import express from "express";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DIST = path.join(__dirname, "..", "dist");
const PORT = Number(process.env.PORT || 8080);

const app = express();
app.disable("x-powered-by");

app.get("/api/health", (_req, res) => {
  res.json({ ok: true, service: "agent-on-rails-website" });
});

app.use(
  express.static(DIST, {
    extensions: ["html"],
    setHeaders(res, filePath) {
      if (filePath.endsWith(".html")) {
        res.setHeader("Cache-Control", "public, max-age=60");
      } else if (/[/\\]brand[/\\]/i.test(filePath)) {
        // Brand marks change without hashed filenames; avoid week-long immutable CDN sticky.
        res.setHeader("Cache-Control", "public, max-age=300");
      } else if (/\.(?:js|css|png|jpg|jpeg|svg|webp|woff2)$/i.test(filePath)) {
        res.setHeader("Cache-Control", "public, max-age=604800, immutable");
      }
    },
  }),
);

app.use((_req, res) => {
  res.status(404).sendFile(path.join(DIST, "404.html"), (err) => {
    if (err) res.status(404).type("text").send("Not found");
  });
});

app.listen(PORT, () => {
  console.log(`agent-on-rails-website listening on :${PORT}`);
});
