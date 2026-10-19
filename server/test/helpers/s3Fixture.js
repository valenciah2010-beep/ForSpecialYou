import http from "node:http";

// Local S3 wire fixture: exercises the actual SDK without any cloud credentials.
export async function startS3Fixture() {
  const objects = new Map();
  const requests = [];
  let failing = false;
  const xml = (value) =>
    String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;");
  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, "http://localhost");
    const key = decodeURIComponent(url.pathname.split("/").slice(2).join("/"));
    requests.push({ method: req.method, key, headers: req.headers });
    if (failing) {
      res.writeHead(403, { "Content-Type": "application/xml" });
      res.end(
        "<Error><Code>AccessDenied</Code><Message>Private upstream detail</Message></Error>",
      );
      return;
    }
    if (url.searchParams.get("list-type") === "2") {
      const prefix = url.searchParams.get("prefix") || "";
      const keys = [...objects.keys()]
        .filter((key) => key.startsWith(prefix))
        .sort();
      const offset = Number(url.searchParams.get("continuation-token") || 0);
      // Force pagination even with a tiny fixture.
      const page = keys.slice(offset, offset + 2);
      const more = offset + page.length < keys.length;
      res.writeHead(200, { "Content-Type": "application/xml" });
      res.end(
        `<ListBucketResult><IsTruncated>${more}</IsTruncated>${more ? `<NextContinuationToken>${offset + 2}</NextContinuationToken>` : ""}${page.map((key) => `<Contents><Key>${xml(key)}</Key></Contents>`).join("")}</ListBucketResult>`,
      );
    } else if (req.method === "PUT") {
      const parts = [];
      for await (const part of req) parts.push(part);
      objects.set(key, Buffer.concat(parts));
      res.writeHead(200, { ETag: '"fixture"' });
      res.end();
    } else if (req.method === "DELETE") {
      objects.delete(key);
      res.writeHead(204);
      res.end();
    } else if (req.method === "GET" && objects.has(key)) {
      res.writeHead(200, { "Content-Type": "image/jpeg" });
      res.end(objects.get(key));
    } else {
      res.writeHead(404, { "Content-Type": "application/xml" });
      res.end("<Error><Code>NoSuchKey</Code></Error>");
    }
  });
  server.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  return {
    objects,
    requests,
    settings: {
      endpoint: `http://127.0.0.1:${server.address().port}`,
      bucket: "test",
      accessKeyId: "fixture",
      secretAccessKey: "fixture",
    },
    fail: (value) => {
      failing = value;
    },
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}
