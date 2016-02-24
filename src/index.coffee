
_ = require("lodash")
request = require("co-request")

USER_AGENT = "gh-migrations (https://github.com/jneill/gh-migrations)"

class Api

  constructor: (token) ->
    @_client = new Client(token)

  migrations: (organization) ->
    @migrations = new Migrations(@_client, organization)

class Migrations

  constructor: (client, organization) ->
    @org = organization
    @_client = client

  find: ->
    yield @_client.get("/orgs/#{@org}/migrations")

  get: (id) ->
    yield @_client.get("/orgs/#{@org}/migrations/#{id}")

  create: (repositories) ->
    yield @_client.post("/orgs/#{@org}/migrations", { body: { repositories } })

  download: (id) ->
    @_client.stream "GET", "/orgs/#{@org}/migrations/#{id}/archive",
      json: false
      encoding: null

class Client

  mergeOptions = (method, uri = "", options = {}) ->
    if _.isObject(uri)
      options = uri
      options.uri or= ""
    else if _.isString(uri)
      options.uri = uri
    options.method = method
    options

  constructor: (token) ->
    @_requestDefaults =
      baseUrl: "https://api.github.com"
      json: true
      headers:
        "User-Agent": USER_AGENT
        "Authorization": "token #{token}"
        "Accept": "application/vnd.github.wyandotte-preview+json"
    @_request = request.defaults(@_requestDefaults)

  stream: (method, uri, options) ->
    options = mergeOptions(method, uri, options)
    _.defaults(options, { json: false, encoding: null }, @_requestDefaults)
    # don't use co-request because we want the stream
    require("request")(options)

  request: (method, uri, options) ->
    options = mergeOptions(method, uri, options)
    res = yield @_request(options)
    res.body

  get: (uri, options) ->
    yield @request("GET", uri, options)

  post: (uri, options) ->
    yield @request("POST", uri, options)

module.exports = Api
