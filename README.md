## gh-migrations

Export all of an organization's GitHub data using the (in preview) [Migrations API](https://developer.github.com/v3/migration/migrations/)

Create a migration and then download the archive, containing each repository's:

* `.git` directory
* Wiki (as git repo)
* Issues
* Pull Requests
* Comments
* Releases
* Milestones
* Events (e.g. issue closed then reopened)
* Attachments (e.g. images in comments)

**Note** This is a temporary hack until the Migrations API comes out of preview and GitHub presumably provide a proper UI for it. It's an an extremely rough-and-ready tool: no tests, no error handling.

### Installation

Requires [node.js](https://nodejs.org/) (>= 4.0)

```
$ npm install -g gh-migrations
```

### Configuration

The tool can be configured using options on the command-line, or in `~/.gh.json` (as for [node-gh](https://github.com/node-gh/gh#config))

```json
{
  "github_token": "e72e16c7e42f292c6912e7710c838347ae178b4a",
  "default_org": "octokit"
}
```

##### OAuth Token

This is the token used to access the GitHub API. You'll need to [create a new personal access token](https://github.com/settings/tokens/new?scopes=repo&description=gh-migrations) with `repo` scope. You can set the token using the `--token` option on the command-line, or as `"github_token"` in `~/.gh.json`

##### Organization

Migrations are created in the scope of a GitHub Organization. You can set the organization name using the `--org` option on the command-line, or as `"default_org"` in `~/.gh.json`

### Usage

Create a new migration, specifying the list of repositories to include. Repository names need to be the full name (i.e. of the form `{user}/{repo}`)

```
$ gh-migrations create octokit/octokit.net octokit/go-octokit octokit/octokit.rb
Migration 4797
  State:   pending
  Created: Mon Nov 8 12:25:35 2016 +0000
  Updated: Mon Nov 8 12:25:36 2016 +0000
  Repositories:
    octokit/octokit.net
    octokit/go-octokit
    octokit/octokit.rb
```

View the list of existing migrations

```
$ gh-migrations list
┌──────────┬───────────┬─────────────────┬────────────────────────────────────┐
│ ID       │ State     │ Updated         │ Repositories                       │
├──────────┼───────────┼─────────────────┼────────────────────────────────────┤
│ 4797     │ exporting │ 1 minute ago    │ octokit/octokit.net                │
│          │           │                 │ octokit/go-octokit                 │
│          │           │                 │ octokit/octokit.rb                 │
├──────────┼───────────┼─────────────────┼────────────────────────────────────┤
│ 4791     │ exported  │ 9 hours ago     │ octokit/octokit.py                 │
└──────────┴───────────┴─────────────────┴────────────────────────────────────┘
```

Once the migration state changes to `exported`, you can download the archive:

```
$ gh-migrations download 4797 > gh4797.tar.gz
```

### Library

This tool can also be used as a node module to access the Migrations API.

The library uses [ES6 generators](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*) and [`co`](https://github.com/tj/co) to emulate [ES7 async/await](https://github.com/lukehoban/ecmascript-asyncawait).

```coffeescript
Api = require("gh-migrations")

api = new Api(token)
migrations = api.migrations("octokit")

co ->
  migration = yield migrations.create([ "octokit/octokit.objc" ])
  console.log migration.state # pending

  # later
  list = yield migrations.findAll()
  migration = _.find(list, (m) -> m.id is migration.id)
  console.log migration.state # exporting

  # later still
  migration = yield migrations.get(migration.id)
  console.log migration.state # exported

  migrations.download(migration.id)
    .pipe(fs.createWriteStream("out.tar.gz"))
```
