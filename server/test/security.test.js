import test from "node:test";
import assert from "node:assert/strict";
import sharp from "sharp";
import { parseCookies } from "../src/services/adminSession.js";
import { sanitizeImage, validateImageData } from "../src/services/images.js";
import { deidentify } from "../src/services/aiPrivacy.js";
import { jsonBodyParser } from "../src/middleware/bodyParser.js";
import { csrfProtection } from "../src/middleware/security.js";
import { isValidPassword } from "../src/utils/validators.js";

test("password validation rejects silent bcrypt UTF-8 truncation", () => {
  assert.equal(isValidPassword("a".repeat(71) + "1"), true);
  assert.equal(isValidPassword("密".repeat(24) + "1"), false);
  assert.equal(isValidPassword("a".repeat(72) + "1"), false);
});

test("malformed cookies cannot crash authentication or change prototypes", () => {
  const cookies = parseCookies("bad=%zz; __proto__=bad; good=ok");
  assert.equal(cookies.good, "ok");
  assert.equal(Object.getPrototypeOf(cookies), null);
});
test("image decoder rejects spoofed content and strips metadata", async () => {
  await assert.rejects(() =>
    validateImageData(
      "data:image/jpeg;base64," + Buffer.from("<svg/>").toString("base64"),
    ),
  );
  const image = await sharp({
    create: { width: 30, height: 20, channels: 3, background: "#225544" },
  })
    .jpeg()
    .withMetadata({ exif: { IFD0: { Artist: "Private person" } } })
    .toBuffer();
  const metadata = await sharp(await sanitizeImage(image)).metadata();
  assert.equal(metadata.width, 30);
  assert.equal(metadata.exif, undefined);
});
test("private profile and free-text fields are excluded from AI payload", () => {
  const output = deidentify({
    name: "private",
    email: "private",
    comments: "private",
    title: "sleep",
    severity: 2,
  });
  assert.deepEqual(output, { title: "sleep", severity: 2 });
});
test("downstream errors are not mistaken for invalid JSON", async () => {
  const ctx = {
    method: "POST",
    path: "/api/test",
    get: () => "application/json",
    req: (async function* () {
      yield Buffer.from("{}");
    })(),
    request: {},
  };
  await assert.rejects(
    () =>
      jsonBodyParser()(ctx, () => {
        throw new Error("database failure");
      }),
    /database failure/,
  );
});
test("JSON primitives and malformed data are rejected", async () => {
  for (const body of ["null", "[]", '"text"', "{"]) {
    const ctx = {
      method: "POST",
      path: "/api/test",
      get: () => "application/json",
      req: (async function* () {
        yield Buffer.from(body);
      })(),
      request: {},
    };
    await jsonBodyParser()(ctx, () =>
      assert.fail("Must reject before routing"),
    );
    assert.equal(ctx.status, 400);
  }
});
test("CSRF rejects cross-site cookie mutations and missing origin", async () => {
  for (const origin of ["https://attacker.invalid", ""]) {
    const ctx = {
      method: "DELETE",
      path: "/api/users/1",
      get: (name) =>
        ({
          cookie: "care_portal_admin_session=x",
          origin,
          "x-requested-with": "CarePortal",
        })[name] || "",
    };
    await csrfProtection(ctx, () => assert.fail("Untrusted mutation"));
    assert.equal(ctx.status, 403);
  }
});

test("free-text identity embedded in measurements is not sent to AI", () => {
  assert.deepEqual(
    deidentify({ value: "Patient Jane at 123 Main Street" }),
    {},
  );
  assert.deepEqual(deidentify({ value: "7 hours" }), { value: "7 hours" });
});
