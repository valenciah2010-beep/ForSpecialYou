export function jsonBodyParser({ limitBytes = 20 * 1024 * 1024 } = {}) {
  return async (ctx, next) => {
    if (!["POST", "PUT", "PATCH", "DELETE"].includes(ctx.method)) {
      return next();
    }

    const contentType = ctx.get("content-type") || "";
    if (!contentType.includes("application/json")) {
      ctx.request.body = {};
      return next();
    }

    const effectiveLimit = ctx.path.includes("/chunks/") ? 720000 : limitBytes;
    const chunks = [];
    let size = 0;

    try {
      for await (const chunk of ctx.req) {
        size += chunk.length;
        if (size > effectiveLimit) {
          ctx.status = 413;
          ctx.body = { message: "Request body is too large." };
          return;
        }
        chunks.push(chunk);
      }

      const rawBody = Buffer.concat(chunks).toString("utf8").trim();
      ctx.request.body = rawBody ? JSON.parse(rawBody) : {};
      if (
        !ctx.request.body ||
        typeof ctx.request.body !== "object" ||
        Array.isArray(ctx.request.body)
      )
        throw new Error("Invalid body");
    } catch {
      ctx.status = 400;
      ctx.body = { message: "Request body must be valid JSON." };
      return;
    }
    return next();
  };
}
