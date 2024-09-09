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
    const virtualHost = "matrix2.ayats.org";

    if (pathname === "/.well-known/matrix/server") {
      data = {
        "m.server": `${virtualHost}:443`,
      };
    } else if (pathname === "/.well-known/matrix/client") {
      data = {
        "m.homeserver": {
          base_url: `https://${virtualHost}`,
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

