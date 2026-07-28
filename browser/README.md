# browser

A userscript that puts a button on Jira issues and Bitbucket pull requests to
drop them onto today's Seedling list.

- `seedling.user.js` — the script. Pure helpers at the top (URL detection, task
  titles, the Firestore document); browser wiring below, guarded so Node can
  import the helpers.
- `test/userscript.test.js` — `node --test`, no dependencies.

## Why a userscript and not an extension

Two extensions means two manifests, two packaging paths and two dev-loading
dances for one button. Tampermonkey and Greasemonkey both run this file
unchanged, so Chrome and Firefox are covered by one thing to maintain. If it
ever needs to do more than add a task, an extension becomes worth it.

## Installing

1. Install Tampermonkey (Chrome) or Greasemonkey/Tampermonkey (Firefox).
2. Create a new script and paste `seedling.user.js` in, or open the raw file and
   let the extension offer to install it.
3. Open a Jira issue. A **🌱 Pick up** button appears bottom-right; on a
   Bitbucket pull request it reads **🌱 Review today**.
4. The first click asks for your Seedling email and password. It signs in once,
   stores only the refresh token, and never keeps the password.

Optional: the Tampermonkey menu has **Seedling: set tag id** if you want these
filed under a project. The id is the document id shown in the tags screen — for
a tag named "Work" it will be `work`.

## What it adds

| Page | Task |
|---|---|
| `…/browse/MED-1234` | `MED-1234 Fix the login bug` |
| Board with `?selectedIssue=MED-99` | `MED-99 <summary>` |
| `bitbucket.org/ws/backend/pull-requests/42` | `Review backend#42: Add caching` |

Tasks land on today, open and untimed, so the rollover rule carries them
forward until you tick them off.

## How it gets the title

It asks Jira and Bitbucket's own REST APIs from the page itself, using your
existing session cookies — `/rest/api/3/issue/KEY` and `/!api/2.0/…`. That
survives their UI being rewritten, which DOM scraping does not. If the call
fails it falls back to the tab title rather than refusing to add anything.

## Auth

Straight to Firestore over REST, the same path the app uses, so there is no
server in between:

1. `accounts:signInWithPassword` once → refresh token, stored.
2. `securetoken.googleapis.com/v1/token` → a one-hour access token, cached and
   renewed a minute before it lapses.
3. `POST users/{uid}/tasks` with the document in `taskDocument()`.

The API key in the file is public by design — it names the project, it grants
nothing. `firestore.rules` is what keeps the data yours; a token for another
account cannot read or write your subtree.

## Tests

```
cd browser && node --test
```

Covers URL detection (including board deep links and near-miss keys), the task
titles, and that the document matches the app's `Task` model field for field —
that last one is the bit that breaks silently if the model ever changes.

The auth flow and the write itself were verified against the real project with
the test account: sign in, refresh, write, read back, delete.
