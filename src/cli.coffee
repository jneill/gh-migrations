
fs = require("co-fs")
os = require("os")
path = require("path")

_ = require("lodash")
co = require("co")
moment = require("moment")
Table = require("cli-table")

Api = require("./index")

TIME_FORMAT = "ddd MMM D HH:mm:ss YYYY ZZ"

getConfig = ->
  options = program.opts()
  try json = yield fs.readFile(path.join(os.homedir(), ".gh.json"), "UTF8")
  globalConfig = if json then JSON.parse(json) else {}
  return {
    token: options.token or globalConfig.github_token
    org: options.org or globalConfig.default_org
  }

migrations = ->
  { token, org } = yield getConfig()
  new Api(token).migrations(org)

program = require("commander")

program
  .version "1.0.0"
  .description "GitHub Migrations CLI"
  .option("-t, --token [token]", "a valid GitHub OAuth2 token")
  .option("-o, --org [org]", "name of the organisation to migrate")

program
  .command "create [repos...]"
  .description "create new migration"
  .action (repos) -> execAsync ->
    migrations = yield migrations()
    item = yield migrations.create(repos)
    process.stdout.write formatItem(item) + "\n"

program
  .command "list"
  .description "list existing migrations"
  .action -> execAsync ->
    migrations = yield migrations()
    list = yield migrations.find()
    process.stdout.write formatList(list) + "\n"

program
  .command "view [id]"
  .description "view existing migration"
  .action (id) -> execAsync ->
    migrations = yield migrations()
    item = yield migrations.get(id)
    process.stdout.write formatItem(item) + "\n"

program
  .command "download [id]"
  .description "download migration archive"
  .action (id) -> execAsync ->
    migrations = yield migrations()
    content = migrations.download(id)
    content.pipe(process.stdout)

execAsync = (fn) ->
  co(fn).catch (err) ->
    process.stderr.write(err.stack) + "\n"
    process.exit(1)

formatList = (migrations) ->
  table = new Table
    head: [ "ID", "State", "Updated", "Repositories" ]
    colWidths: [ 10, 11, 17, 36 ]
    style: { head: [ "bold", "cyan" ], border: [ "white" ] }
  for migration in migrations
    table.push [
      migration.id
      migration.state
      moment(migration.updated_at).fromNow()
      _.map(migration.repositories, "full_name").join("\n")
    ]
  return table.toString()

formatItem = (migration) ->
  """
  Migration #{migration.id}
    State:   #{migration.state}
    Created: #{moment(migration.created_at).format(TIME_FORMAT)}
    Updated: #{moment(migration.updated_at).format(TIME_FORMAT)}
    Repositories:
      #{_.map(migration.repositories, "full_name").join("\n    ")}
  """

module.exports =
  run: ({ argv } = process) ->
    command = argv[2]
    program.help() unless command in [
      "list", "create", "view", "download"
    ]
    program.parse(argv)
