// @ts-check
"use strict";

import assert from "node:assert";

const client_id = process.env.TS_CLIENT_ID;
const client_secret = process.env.TS_CLIENT_SECRET;
const tailnet = "vulture-ratio.ts.net";

// @returns {Promise<string>}
async function get_token() {
  if (!client_id || !client_secret) {
    throw new Error("TS_CLIENT_ID and TS_CLIENT_SECRET must be set");
  }

  const resp = await fetch("https://api.tailscale.com/api/v2/oauth/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id,
      client_secret,
    }),
  });

  // Throw if resp not ok
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(
      `Failed to get token: ${resp.status} ${resp.statusText}: ${text}`
    );
  }

  const json = await resp.json();

  assert(typeof json.access_token === "string", "access_token is not a string");

  return json.access_token;
}

const access_token = await get_token();

const resp = await fetch(
  `https://api.tailscale.com/api/v2/tailnet/${tailnet}/keys`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${access_token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      description: "neoinfra-automated",
      capabilities: {
        devices: {
          create: {
            reusable: true,
            ephemeral: true,
            preauthorized: true,
            tags: ["tag:server"],
          },
        },
      },
      expirySeconds: 60 * 60 * 24 * 3, // 3 days
      scopes: ["all:read"],
      tags: ["tag:server"],
    }),
  }
);

assert(resp.ok, `Failed to create key: ${resp.status} ${resp.statusText}`);

const json = await resp.json();
assert(typeof json.key === "string", "key is not a string");
console.log(json.key);
