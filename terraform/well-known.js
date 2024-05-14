/**
 * @satisfies {ExportedHandler}
 */
const res = {
  /**
   *
   * @param {Response} request
   * @returns {Promise<Response>}
   */
  async fetch(request) {
    const { pathname } = new URL(request.url);

    let data = {};

    if (pathname === "/.well-known/matrix/server") {
      data = {
        "m.server": "matrix.ayats.org:443",
      };
    } else if (pathname === "/.well-known/matrix/client") {
      data = {
        "m.homeserver": {
          base_url: "https://matrix.ayats.org",
        }
      }
    };

    const res = Response.json(data);

    res.headers.append(
      "Access-Control-Allow-Origin", "*"
    );

    return res
  }
}

export default res;

