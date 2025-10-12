/// <reference types="@cloudflare/workers-types" />
// @ts-check

/** PostHog API host for the US region. Change to "eu.i.posthog.com" for the EU region */
const API_HOST = "eu.i.posthog.com"
/** PostHog assets host for the US region. Change to "eu-assets.i.posthog.com" for the EU region */
const ASSET_HOST = "eu-assets.i.posthog.com"

/**
 * Main request handler that routes requests to either static asset retrieval or API forwarding
 * @param {Request} request - The incoming request object
 * @param {ExecutionContext} ctx - The execution context for the worker
 * @returns {Promise<Response>} The response from either static assets or the API
 */
async function handleRequest(request, ctx) {
  const url = new URL(request.url)
  const pathname = url.pathname
  const search = url.search
  const pathWithParams = pathname + search

  if (pathname.startsWith("/static/")) {
      return retrieveStatic(request, pathWithParams, ctx)
  } else {
      return forwardRequest(request, pathWithParams)
  }
}

/**
 * Retrieves static assets from PostHog, using Cloudflare cache for performance
 * @param {Request} request - The original request object
 * @param {string} pathname - The pathname of the static asset
 * @param {ExecutionContext} ctx - The execution context for cache operations
 * @returns {Promise<Response>} The cached or freshly fetched static asset
 */
async function retrieveStatic(request, pathname, ctx) {
  const cache = /** @type {any} */ (caches).default;
  let response = await cache.match(request)
  if (!response) {
      response = await fetch(`https://${ASSET_HOST}${pathname}`)
      ctx.waitUntil(cache.put(request, response.clone()))
  }
  return response
}

/**
 * Forwards a request to the PostHog API, removing cookies for privacy
 * @param {Request} request - The original request object
 * @param {string} pathWithSearch - The pathname and search params to forward
 * @returns {Promise<Response>} The response from the PostHog API
 */
async function forwardRequest(request, pathWithSearch) {
  const originRequest = new Request(request)
  originRequest.headers.delete("cookie")
  return await fetch(`https://${API_HOST}${pathWithSearch}`, originRequest)
}

/**
 * Cloudflare Worker export with fetch handler
 * @type {ExportedHandler}
 */
export default {
  async fetch(request, env, ctx) {
    return handleRequest(request, ctx);
  }
};
