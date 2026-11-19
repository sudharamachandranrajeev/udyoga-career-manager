# Site recipes

A recipe is a small JSON file that teaches Udyoga about one website. Udyoga
ships only the engine that runs recipes. It has no recipes of its own.

You keep your recipes in a folder you choose, such as your career file's
`recipes/` folder. In Udyoga, open **Settings → Recipes → Recipes folder**
and pick that folder. The card then lists every recipe it loaded, with its
mode and today's use against its cap. It also lists every file it refused,
with the reason.

## What a recipe can do

Each recipe has one **mode**:

| Mode | What it does |
| --- | --- |
| `fetch` | Reads the site's jobs in the background, during the normal job refresh. It goes through Udyoga's politeness layer: it checks robots.txt (kept for a week), waits `rate` seconds between requests to the site, stops at `dailyCap` requests a day, and skips pages it read in the last 7 days. |
| `browser-read` | Reads a page that **you** have opened in Udyoga's browser, when you press **Read this page**. It never loads pages by itself. |
| `assist-fill` | Types a draft that **you** have approved into one text box on the page you have open, such as a connection note or a message. You press **Fill a text box**, check the dry run, and then press Send or Submit on the page yourself. |

### Hard rules (the engine enforces these, whatever a recipe says)

- **No `fetch` on sites that forbid it.** Recipes for `linkedin.com`,
  `indeed.*` or `glassdoor.*` (any country ending, any subdomain) are
  refused in `fetch` mode. Use `browser-read` for pages you open yourself.
- **A `fetch` recipe must set `"robots": true`**, wait at least 5 seconds
  between requests, and read jobs only.
- **Udyoga never clicks.** The fill code can set the value of a text box and
  nothing else. It has no way to click, submit or press keys. A recipe must
  say `"neverClick": true`, and a `targetSelector` that names a button is
  refused.
- **Dry run first.** Before every fill, Udyoga shows the exact text, the
  target box and today's count against the cap. Nothing happens until you
  confirm.
- **Daily caps.** Every recipe has a `dailyCap`. LinkedIn fills are capped
  at **15 a day in all**: every recipe whose site is linkedin.com shares
  those 15, and each recipe's own cap still applies. Fill counts sync between
  your devices, so the caps hold for your account, not for each device.
  Counts older than 7 days are deleted.
- **Strict checking.** A file with an unknown field, an unknown mode, or a
  missing `rate` or `dailyCap` is refused as a whole.

## Schema

| Field | Type | Needed | Meaning |
| --- | --- | --- | --- |
| `id` | string | yes | Lower-case letters, digits and dashes, unique in the folder. |
| `name` | string | no | The name shown in Settings. When it is missing, Settings shows `site`. |
| `site` | string | yes | The site's host, for example `jobs.example.org`. |
| `urlPatterns` | list of strings | yes | The pages the recipe applies to, as `https://` addresses on `site`. `*` matches anything. |
| `mode` | string | yes | `fetch`, `browser-read` or `assist-fill`. |
| `record` | string | no | What a page becomes: `job` (the default), `person` or `company`. `fetch` reads jobs only. |
| `rate` | number | yes | The fewest seconds between two requests, or between two fills. The minimum is 1, and 5 for `fetch`. |
| `dailyCap` | whole number | yes | The most requests a day on this device (for `fetch`), or the most fills a day across all your devices (for `assist-fill`). |
| `robots` | true/false | for `fetch` | Must be `true` for `fetch`: robots.txt is obeyed. |
| `list` | object | for `fetch` | The search page and its job links (see below). |
| `detail` | object | for `fetch` and `browser-read` | How to read one page into a record (see below). |
| `fill` | object | for `assist-fill` | Which text box gets which text (see below). |
| `notes` | string | no | Your own notes. Udyoga ignores them. |

### `list` (fetch only)

| Field | Meaning |
| --- | --- |
| `url` | The search page, an `https://` address on `site`. `{terms}` is replaced with your profile's search terms. |
| `item` | A CSS selector for each job link on that page, for example `a.vacancy-link`. |
| `attr` | The attribute that holds the link. The default is `href`. |
| `max` | The most job pages read in one run, from 1 to 100. The default is 10. |

Only links that match `urlPatterns` are followed.

### `detail` (fetch and browser-read)

| Field | Meaning |
| --- | --- |
| `jsonLd` | A schema.org type to read from the page's JSON-LD, for example `JobPosting`. For a JobPosting, its fields fill any gaps the selectors leave. |
| `fields` | A map from a record field to where its value is (see below). |

Each value in `fields` is one of these:

- a CSS selector, which gives the element's text, for example `h1.job-title`;
- a CSS selector followed by `@attribute`, which gives that attribute, for example `a.apply@href`;
- `ld:` followed by a path into the JSON-LD object, for example `ld:hiringOrganization.name`.

The record fields are:

| Record | Fields |
| --- | --- |
| `job` | `title`, `company`, `location`, `salary`, `closing`, `posted`, `reference`, `description` |
| `person` | `name`, `title`, `company`, `email`, `phone`, `profileUrl` |
| `company` | `name`, `website`, `location`, `about` |

### `fill` (assist-fill only)

| Field | Meaning |
| --- | --- |
| `targetSelector` | A CSS selector for the text box: a `textarea`, a text `input` or a `contenteditable` element. Buttons are refused. |
| `templateSource` | `draft`: the text you write, paste or pick from your saved drafts in Udyoga, and approve. The saved drafts are the LinkedIn studio's connection notes and messages, and the drafts and intro messages written for a conversation or a contact. `recipe`: the recipe's own `template`, which you can still edit before the dry run. |
| `template` | For `recipe`: the text, with `{firstName}`, `{name}`, `{company}` and `{jobTitle}` filled from the page. |
| `maxLength` | The box's character limit. The text is cut to fit, and the dry run says so. Use 0 for no limit. |
| `neverClick` | Must be `true`. |

## Example (fictional)

`jobs.example.org` is a made-up site. Save these as `.json` files in your
recipes folder. A file may hold one recipe, or a list of recipes.

```json
[
  {
    "id": "example-jobs-fetch",
    "name": "Example Jobs",
    "site": "jobs.example.org",
    "urlPatterns": ["https://jobs.example.org/vacancy/*"],
    "mode": "fetch",
    "rate": 20,
    "dailyCap": 30,
    "robots": true,
    "list": {
      "url": "https://jobs.example.org/search?q={terms}",
      "item": "a.vacancy-link",
      "max": 10
    },
    "detail": {
      "jsonLd": "JobPosting",
      "fields": {
        "title": "h1.vacancy-title",
        "company": ".employer-name",
        "location": ".vacancy-location",
        "salary": ".vacancy-salary",
        "closing": ".closing-date",
        "reference": ".vacancy-ref",
        "description": "#vacancy-description"
      }
    }
  },
  {
    "id": "example-jobs-contacts",
    "site": "jobs.example.org",
    "urlPatterns": ["https://jobs.example.org/team/*"],
    "mode": "browser-read",
    "record": "person",
    "rate": 1,
    "dailyCap": 50,
    "detail": {
      "fields": {
        "name": ".profile h1",
        "title": ".profile .role",
        "company": "ld:worksFor.name",
        "profileUrl": "a.profile-link@href"
      }
    }
  },
  {
    "id": "example-jobs-message",
    "site": "jobs.example.org",
    "urlPatterns": ["https://jobs.example.org/messages/new*"],
    "mode": "assist-fill",
    "rate": 30,
    "dailyCap": 10,
    "fill": {
      "targetSelector": "textarea#message-body",
      "templateSource": "draft",
      "maxLength": 1000,
      "neverClick": true
    }
  }
]
```

## The page reader

**Read this page** is in the toolbar of Udyoga's browser on Linux, Windows
and Android. It does nothing until you press it. When you press it, Udyoga:

1. Reads the page's text and its schema.org markup (JobPosting, Person and
   Organization), plus any `browser-read` recipe for the page.
2. If the page has little text (a canvas or a PDF, for example), offers to
   read a screenshot instead. It uses the page's own picture when the page
   allows that. Otherwise it asks you to take a screenshot and choose it.
   The screenshot is read by one of these:
   - **Tesseract** on Linux and Windows, if you have installed it. Udyoga
     does not bundle it.
   - **Google ML Kit** on Android, only after you agree. ML Kit reads the
     text on the phone, but Google's SDK sends usage information (the phone
     model, the Android version, the app and how the reading performed),
     and there is no setting to stop that.
   - **Your AI**, only if you choose it and its model reads images: the
     Claude API, Gemini, or your Claude subscription. The ChatGPT
     subscription does not read images in Udyoga. The screenshot is sent to
     that provider.
3. Shows each job, person and employer it found, with fields you can edit.
   Nothing is ticked at first, and nothing is saved until you tick records
   and press **Keep**.
