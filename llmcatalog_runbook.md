# LLM Catalog Domain Migration Runbook

This runbook moves the public site from `https://llmdb.xyz` to
`https://llmcatalog.dev`.

Use this file as the task record for the migration. Add the owner, date, result,
and links to pull requests or dashboards as work is completed.

## Migration record

- Status: Technical cutover complete; external service follow-up pending
- Migration owner: Mike Hostetler
- Code owner: Mike Hostetler
- DNS owner: Mike Hostetler
- Search owner: Mike Hostetler
- Planned cutover time: `2026-08-12`
- Actual cutover time: `2026-08-12 13:16 UTC`
- Pull requests: [#91](https://github.com/agentjido/llmcatalog/pull/91),
  [#92](https://github.com/agentjido/llmcatalog/pull/92)
- Final code deployment:
  [GitHub Actions run 31601028547](https://github.com/agentjido/llmcatalog/actions/runs/31601028547)
- Cloudflare zones: `llmcatalog.dev`, `llmdb.xyz`
- Plausible site: `llmdb.xyz` -> `llmcatalog.dev`
- Google Search Console move: `llmdb.xyz` -> `llmcatalog.dev`
- Rollback decision owner: Mike Hostetler

## Fixed decisions

- [x] Use **LLM Catalog** as the public product name.
- [x] Use `https://llmcatalog.dev` as the canonical origin.
- [x] Use the apex domain. Redirect `www.llmcatalog.dev` to the apex domain.
- [x] Keep all current URL paths. Do not change the site structure during the
  domain move.
- [x] Keep the Fly application name `llmdb-prod`.
- [x] Keep the internal Phoenix application and module names unchanged.
- [x] Keep `llmdb.xyz` registered and active for at least one year. An
  indefinite redirect is preferred.
- [x] Keep `llmdb.dev` out of scope. Do not change its DNS or application
  support during this migration.
- [x] Keep `POST /api/mcp` operational on `llmdb.xyz`. Do not depend on a
  client following a redirect for this endpoint.

Recommended public description:

> LLM Catalog is powered by LLMDB. Install the Elixir package as `llm_db`.

## Success criteria

- [x] `https://llmcatalog.dev/` loads with a valid certificate.
- [x] LiveView navigation and WebSocket connections work on the new domain.
- [x] Every public GET and HEAD URL on `llmdb.xyz` redirects to the same path
  and query on `llmcatalog.dev`.
- [x] Every public GET and HEAD URL on `www.llmdb.xyz` redirects to the same
  path and query on `llmcatalog.dev`.
- [x] `POST https://llmdb.xyz/api/mcp` still returns an MCP response without a
  redirect.
- [x] `www.llmcatalog.dev` redirects to `llmcatalog.dev` in one hop.
- [x] Canonical tags, structured data, `robots.txt`, the sitemap, the RSS feed,
  Markdown responses, and social images use the new domain.
- [ ] Plausible receives page views and custom events for `llmcatalog.dev`.
- [ ] Google Search Console accepts the Change of Address request.
- [x] The old domain has no redirect loops or broken important URLs.
- [x] The production health check stays green during the move.

## Current state recorded on 2026-08-12

- Production Fly application: `llmdb-prod`
- Fly hostname: `llmdb-prod.fly.dev`
- Fly region: `ord`
- Fly IPv4 address: `66.241.124.27`
- Fly IPv6 address: `2a09:8280:1::ad:9b93:0`
- Current Fly certificates: `llmdb.xyz`, `www.llmdb.xyz`, `llmcatalog.dev`,
  and `www.llmcatalog.dev`; all four are issued.
- Current production image at audit time:
  `llmdb-prod:deployment-01KZTVTK1KZJHF0D77JT5H7GQD`
- Current production machine version at audit time: `98`
- Final code release: `llmdb-prod:deployment-01KZV26891BPS6FCTTR4CJP6RK`
- Final code release machine version: `101`
- `PHX_HOST` and `CANONICAL_HOST` are set as Fly secrets. These secrets can
  override values in the TOML files.
- The production GitHub workflow deploys with `build/llmdb-prod.toml`.
- `llmcatalog.dev` is active on Cloudflare:
  - Nameservers: `pearl.ns.cloudflare.com`, `robert.ns.cloudflare.com`
  - Apex A record: `66.241.124.27`
  - Apex AAAA record: `2a09:8280:1::ad:9b93:0`
  - `www` CNAME: `o2depm5.llmdb-prod.fly.dev`
  - Fly ownership and ACME validation records are present.
- `llmdb.xyz` uses Cloudflare nameservers. `www.llmdb.xyz` has DNS-only Fly
  routing, ACME validation, and ownership records.
- The production site uses the LLM Catalog brand and `llmcatalog.dev` URLs.
- Production source-data links use `agentjido/llmdb`.
- `build/llmdb-stage.toml` now refers to `stage.llmcatalog.dev`, but the
  `llmdb-stage` Fly application does not exist.

Recheck the state before the migration. Do not use the recorded image or
machine version as a current rollback target.

## Phase 1: Record a baseline

- [ ] Record the current production image and machine version:

  ```sh
  fly status -a llmdb-prod
  ```

- [ ] Record the current Fly certificates and IP addresses:

  ```sh
  fly certs list -a llmdb-prod
  fly ips list -a llmdb-prod
  ```

- [ ] Record the names of the current Fly secrets. Do not copy secret values
  into this file:

  ```sh
  fly secrets list -a llmdb-prod
  ```

- [ ] Export or capture the current Cloudflare settings for `llmdb.xyz`.
- [ ] Record the current Plausible visitor, page-view, and goal counts.
- [ ] Record the current Google Search Console performance for the last 28 and
  90 days.
- [ ] Export the top landing pages and top linked pages from Search Console.
- [ ] Record the current indexed-page count and sitemap state.
- [ ] Record the current Bing Webmaster Tools state, if the site is present.
- [ ] Save a list of important URLs from the current sitemap:

  ```sh
  curl -fsSL https://llmdb.xyz/sitemap.xml
  ```

- [ ] Confirm that the Git worktree is clean before code work starts:

  ```sh
  git status --short --branch
  ```

## Phase 2: Prepare the code change

Do the code work on a branch. Use a Conventional Commit and a normal pull
request.

### 2.1 Brand and URL changes

- [x] Change visible `llmdb.xyz` text to **LLM Catalog** where the text is a
  product name.
- [x] Change visible domain references to `llmcatalog.dev` where the domain is
  useful to the visitor.
- [x] Change the README title and deployment notes.
- [x] Change the model feedback source text to `llmcatalog.dev`.
- [x] Change all source-data links from
  `https://github.com/agentjido/llm_db` to
  `https://github.com/agentjido/llmdb`.
- [ ] If the website repository is renamed, change website issue links from
  `agentjido/llmdb_xyz` to the final website repository name.
- [x] Keep historical records unchanged when an old URL is part of a historical
  event and changing it would change the record.

Review these code areas:

- [x] `README.md`
- [x] `lib/petal_boilerplate_web/seo.ex`
- [x] `lib/petal_boilerplate/og_image.ex`
- [x] `lib/petal_boilerplate_web/components/layouts/root.html.heex`
- [x] `lib/petal_boilerplate_web/components/model_components.ex`
- [x] `lib/petal_boilerplate_web/controllers/discovery_controller.ex`
- [x] `lib/petal_boilerplate_web/controllers/error_html.ex`
- [x] `lib/petal_boilerplate_web/live/about_live.ex`
- [x] `lib/petal_boilerplate_web/live/llm_models_live.ex`
- [x] `lib/petal_boilerplate_web/live/model_live.ex`
- [x] `lib/petal_boilerplate_web/markdown_content.ex`
- [x] `lib/petal_boilerplate_web/model_metadata_feedback.ex`
- [x] `lib/petal_boilerplate/history.ex`
- [x] `priv/seo/pages/*.md`
- [x] `.github/workflows/check-llmdb-update.yml`
- [x] Tests that assert the old brand, domain, or repository URL

Use this command to find remaining references:

```sh
rg -n --hidden \
  --glob '!.git/**' \
  --glob '!deps/**' \
  --glob '!_build/**' \
  --glob '!assets/node_modules/**' \
  'llmdb\.xyz|stage\.llmdb\.xyz|llmdb_xyz|agentjido/llm_db' .
```

Classify each remaining result as one of these types:

- A required legacy-domain redirect or compatibility test
- A historical record that must stay unchanged
- An internal application name that does not need a change
- A missed public brand, URL, or repository link

### 2.2 Production configuration

- [x] Change `PHX_HOST` to `llmcatalog.dev` in `fly.toml`.
- [x] Change `CANONICAL_HOST` to `llmcatalog.dev` in `fly.toml`.
- [x] Change both values in `build/llmdb-prod.toml`. This file is used by the
  production GitHub workflow.
- [x] Change the Plausible `site_domain` in `config/config.exs` to
  `llmcatalog.dev`.
- [x] Keep the current Plausible script URL unless the Plausible migration
  checklist gives a new value.
- [x] Update `build/llmdb-stage.toml` to
  `stage.llmcatalog.dev` or remove the unused stage configuration in a separate
  cleanup change.
- [x] Do not rename `llmdb-prod` during this migration.
- [x] Do not rename `PetalBoilerplate` modules during this migration.

Important: production also has `PHX_HOST` and `CANONICAL_HOST` secrets. The
committed TOML change does not replace these secret values. Update the secret
values during cutover.

### 2.3 Redirect and MCP compatibility code

The current endpoint uses `PlugCanonicalHost` before the router. It sends a
redirect for all requests to a non-canonical host. A `301` response can cause a
client to change a POST request to a GET request.

- [x] Replace or wrap the current canonical-host plug with site-specific host
  logic.
- [x] Let requests to `llmcatalog.dev` continue normally.
- [x] Send a permanent redirect for normal requests on `llmdb.xyz`.
- [x] Include `www.llmdb.xyz` in the explicit legacy-host list.
- [x] Keep `llmdb.dev` out of the legacy-host list while it is out of scope.
- [x] Preserve the request path and query string.
- [x] Use `308` in application code when the HTTP method must be preserved.
- [x] Let `POST /api/mcp` continue on the configured legacy domains without a
  redirect.
- [x] Keep the legacy-host list explicit. Do not treat an arbitrary Host header
  as trusted.
- [x] Add the redirect in the application and keep Cloudflare in DNS-only mode
  during the migration.

Add automated tests for these cases:

- [x] Canonical host request continues without a redirect.
- [x] Old-domain home-page request redirects to the new home page.
- [x] Old-domain path redirects to the same path.
- [x] Old-domain query string is preserved.
- [x] `www.llmcatalog.dev` redirects to the apex domain.
- [x] `POST /api/mcp` on `llmdb.xyz` does not redirect.
- [x] `POST /api/mcp` on `llmcatalog.dev` succeeds.
- [x] An unknown host does not become part of a generated redirect URL.

### 2.4 SEO and generated output

- [ ] Confirm that `PetalBoilerplateWeb.Endpoint.url/0` returns
  `https://llmcatalog.dev` in production.
- [ ] Confirm that all canonical tags use `llmcatalog.dev`.
- [ ] Confirm that Open Graph and social image URLs use `llmcatalog.dev`.
- [ ] Confirm that JSON-LD uses the new name and domain.
- [ ] Confirm that `/robots.txt` names
  `https://llmcatalog.dev/sitemap.xml`.
- [ ] Confirm that every `<loc>` in `/sitemap.xml` uses the new domain.
- [ ] Confirm that `/feed`, `/llms.txt`, and Markdown responses use the new
  domain.
- [ ] Confirm that generated OG images show **LLM Catalog** or
  `llmcatalog.dev`.
- [ ] Keep URL paths unchanged so every old path has a direct new equivalent.
- [ ] Do not add `noindex` to the production site.

### 2.5 Code verification

- [x] Format the code:

  ```sh
  mix format
  ```

- [x] Run the complete test suite:

  ```sh
  mix test
  ```

- [x] Build the production assets:

  ```sh
  mix assets.build
  ```

- [x] Start the site locally and review the visible name, metadata, feedback
  link, sitemap, feed, Markdown output, and MCP endpoint.
- [x] Complete browser QA at desktop and mobile widths.
- [ ] Review the pull request before merge.

## Phase 3: Add `llmcatalog.dev` to Cloudflare

Reference: [Cloudflare domain management](https://developers.cloudflare.com/fundamentals/manage-domains/)

### 3.1 Add and activate the zone

- [x] Add `llmcatalog.dev` to the correct Cloudflare account.
- [x] Record the two nameservers that Cloudflare assigns:
  - Nameserver 1: `pearl.ns.cloudflare.com`
  - Nameserver 2: `robert.ns.cloudflare.com`
- [x] Review the records that Cloudflare imports.
- [x] Replace the Namecheap parking A record `162.255.119.103`.
- [x] Replace the `www` record that points to `parkingpage.namecheap.com`.
- [x] Preserve valid mail, ownership, and verification records.
- [ ] If DNSSEC is enabled at the registrar, disable the old DNSSEC delegation
  before the nameserver change.
- [x] Change the nameservers at the registrar to the assigned Cloudflare
  nameservers.
- [x] Wait until Cloudflare shows the zone as **Active**.
- [ ] After the zone is active and stable, enable Cloudflare DNSSEC and add the
  DS record at the registrar.

### 3.2 Add the new hostnames to Fly

Add the hostnames before public cutover:

```sh
fly certs add llmcatalog.dev -a llmdb-prod
fly certs add www.llmcatalog.dev -a llmdb-prod
fly certs setup llmcatalog.dev -a llmdb-prod
fly certs setup www.llmcatalog.dev -a llmdb-prod
```

- [x] Add the `_fly-ownership` TXT and `_acme-challenge` CNAME records shown by
  `fly certs setup`.
- [x] Keep ownership-validation records after launch. Fly can need them for
  certificate renewal when Cloudflare proxying is enabled.

Reference: [Fly custom domains](https://fly.io/docs/networking/custom-domain/)

### 3.3 Create the Cloudflare DNS records

Create these records first with **DNS only** proxy status:

| Type | Name | Target | Initial proxy status |
|---|---|---|---|
| A | `@` | `66.241.124.27` | DNS only |
| AAAA | `@` | `2a09:8280:1::ad:9b93:0` | DNS only |
| CNAME | `www` | `llmdb-prod.fly.dev` | DNS only |
| TXT/CNAME | Fly validation name | Value from `fly certs setup` | DNS only |

- [x] Confirm that the authoritative Cloudflare nameservers return the new
  records. Recursive resolver caches can continue to return parking records
  until their old TTL expires.
- [x] Check both Fly certificates:

  ```sh
  fly certs check llmcatalog.dev -a llmdb-prod
  fly certs check www.llmcatalog.dev -a llmdb-prod
  ```

- [x] Do not continue until Fly reports valid certificates for both names.
  The `.dev` top-level domain requires HTTPS in current browsers.
- [ ] In Cloudflare, set SSL/TLS encryption mode to **Full (strict)**.
- [ ] Do not use **Flexible** mode. It can cause redirect loops and it does not
  validate the origin connection.
- [ ] After the origin certificates work, change the web records to
  **Proxied** if Cloudflare proxy service is wanted.
- [ ] Confirm that WebSockets are allowed for Phoenix LiveView.
- [ ] Confirm that no cache rule caches HTML, `/live`, `/_q/e`, or
  `/api/mcp` unexpectedly.

Reference: [Cloudflare Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/)

## Phase 4: Configure redirects

Use the Phoenix application for redirects during this migration. Keep the DNS
records in DNS-only mode. This design sends browser traffic to the new domain
and lets the old host continue to serve `POST /api/mcp` without a redirect.
Do not add a broad Cloudflare redirect that can intercept this MCP request.

### 4.1 New-domain `www` redirect

The application sends `www.llmcatalog.dev` to `llmcatalog.dev` with status
`308`. It preserves the path and query string.

- [x] Add the application redirect.
- [x] Add automated tests for the path, query string, and status.
- [x] Verify the behavior after production cutover.

### 4.2 `llmdb.xyz` browser and crawler redirect

The application sends normal old-domain requests to the same path and query on
`llmcatalog.dev` with status `308`. It serves `POST /api/mcp` on the old host
without a redirect.

- [x] Add the normal-request redirect.
- [x] Add the legacy MCP exception.
- [x] Add automated tests for both behaviors.
- [x] Verify both behaviors after production cutover.

### 4.3 Deferred `llmdb.dev` redirect

No action is planned for `llmdb.dev`. If it becomes part of a later change:

- [ ] Add the domain to Cloudflare.
- [ ] Add valid proxied DNS records.
- [ ] Create the same GET and HEAD redirect rule to `llmcatalog.dev`.
- [ ] Preserve the path and query string.
- [ ] Add Fly certificates and application fallback support if
  `POST /api/mcp` must also work on this domain.

Reference: [Cloudflare redirect settings](https://developers.cloudflare.com/rules/url-forwarding/single-redirects/settings/)
and [Cloudflare hostname redirect example](https://developers.cloudflare.com/rules/url-forwarding/examples/redirect-all-different-hostname/).

## Phase 5: Prepare external services before cutover

### 5.1 Plausible

Plausible keeps historical data when a site domain changes. It accepts events
for both the old and new domain for 72 hours after the change. Complete the
code deployment during this period.

- [x] In Plausible, change the site domain from `llmdb.xyz` to
  `llmcatalog.dev`.
- [x] Confirm that the script configuration is still valid. The site uses
  `plausible.init` and the proxied `/_q/e` endpoint.
- [x] Confirm that this repository has no Stats API integration that uses
  `llmdb.xyz` as its domain argument.
- [ ] Update bookmarked, shared, or embedded dashboard URLs. Plausible does not
  redirect old dashboard URLs.
- [ ] Confirm that existing goals and custom properties remain present.
- [x] After deployment, send a page view and a custom filter event.
- [x] Confirm live traffic in the renamed dashboard. Both event requests
  returned `202` without `x-plausible-dropped`.

Reference: [Plausible domain change](https://plausible.io/docs/change-domain-name)

### 5.2 Google Search Console preparation

- [ ] Confirm verified-owner access to the `llmdb.xyz` Domain property.
- [ ] Add a Domain property for `llmcatalog.dev`.
- [ ] Add the Google TXT verification record in Cloudflare.
- [ ] Verify the new Domain property.
- [ ] Confirm that the same Google account is an owner of both properties.
- [ ] Do not submit Change of Address before the new site and redirects work.

### 5.3 Other external records

- [x] Rename the website repository to `agentjido/llmcatalog`, and update its
  description and homepage URL on GitHub.
- [x] Update the `agentjido/llmdb` repository homepage URL and README links in
  [pull request 298](https://github.com/agentjido/llmdb/pull/298).
- [x] Update the Hex package website metadata in the `llmdb` source. The fix is
  complete but is not released. Publish it with the next normal release.
- [ ] Update AgentJido organization pages and documentation.
- [ ] Update active ReqLLM documentation and examples that link to
  `llmdb.xyz`.
- [ ] Update social profiles, link pages, posts, and saved campaign URLs.
- [ ] Update any uptime monitor, status page, or alert that uses the old host.
- [ ] Update any API or MCP client documentation to prefer
  `https://llmcatalog.dev/api/mcp`.

## Phase 6: Cutover

Complete these tasks in this order.

- [x] Confirm Cloudflare shows `llmcatalog.dev` as active.
- [x] Confirm Fly certificates for the apex and `www` names are valid.
- [x] Keep the new web records in DNS-only mode during this migration.
- [x] Confirm the code pull requests are merged and all CI checks pass.
- [x] Change the Plausible domain. This starts the 72-hour transition.
- [x] Deploy the merged code to `llmdb-prod`.
- [x] Confirm that GitHub Actions used `build/llmdb-prod.toml`.
- [x] Set the production host secrets to the new domain:

  ```sh
  fly secrets set \
    PHX_HOST=llmcatalog.dev \
    CANONICAL_HOST=llmcatalog.dev \
    -a llmdb-prod
  ```

- [x] Wait for the machine restart and health check.
- [x] Confirm `fly status -a llmdb-prod` reports one passing health check.
- [x] Verify the application `www` redirect.
- [x] Verify the application `llmdb.xyz` redirect and MCP exception.
- [x] Add Cloudflare DNS and a Fly certificate for `www.llmdb.xyz`.
- [x] Verify that `www.llmdb.xyz` redirects to `llmcatalog.dev` with the path
  and query string unchanged.
- [x] Record the deployed image and machine version:
  `llmdb-prod:deployment-01KZV26891BPS6FCTTR4CJP6RK`, version `101`.
- [x] Record the exact cutover time: `2026-08-12 13:16 UTC`.

`llmdb.dev` was not in the scope of this cutover.

Do not remove the old Fly certificate or old DNS records during cutover.

## Phase 7: Immediate validation

### 7.1 DNS and TLS

- [x] Check DNS:

  ```sh
  dig +short NS llmcatalog.dev
  dig +short A llmcatalog.dev
  dig +short AAAA llmcatalog.dev
  dig +short CNAME www.llmcatalog.dev
  ```

- [x] Check certificates:

  ```sh
  fly certs check llmcatalog.dev -a llmdb-prod
  fly certs check www.llmcatalog.dev -a llmdb-prod
  ```

- [x] Open the site in a new browser session and confirm there is no TLS
  warning.

### 7.2 New-domain checks

- [x] Home page returns `200`:

  ```sh
  curl -fsSIL https://llmcatalog.dev/
  ```

- [x] Health endpoint returns `200`:

  ```sh
  curl -fsS https://llmcatalog.dev/status
  ```

- [x] `www` redirects in one hop and preserves the path and query:

  ```sh
  curl -sSIL 'https://www.llmcatalog.dev/models/vision?source=qa'
  ```

- [x] The canonical tag uses the new domain:

  ```sh
  curl -fsSL https://llmcatalog.dev/about | rg 'rel="canonical"'
  ```

- [x] `robots.txt` names the new sitemap:

  ```sh
  curl -fsSL https://llmcatalog.dev/robots.txt
  ```

- [x] The sitemap contains no old-domain URL:

  ```sh
  curl -fsSL https://llmcatalog.dev/sitemap.xml | rg 'llmcatalog\.dev'
  ! curl -fsSL https://llmcatalog.dev/sitemap.xml | rg -q 'llmdb\.xyz'
  ```

- [x] Check `/feed`, `/llms.txt`, `/about.md`, representative landing pages,
  a model page, and an OG image.
- [x] Confirm the browser establishes a LiveView WebSocket connection.
- [x] Confirm filter changes and model modal actions work.
- [x] Confirm the **Submit Fix on GitHub** action opens
  `agentjido/llmdb` with the correct issue details.

### 7.3 Old-domain redirect checks

- [x] Home-page redirect:

  ```sh
  curl -sSIL https://llmdb.xyz/
  ```

- [x] Path and query preservation:

  ```sh
  curl -sSIL 'https://llmdb.xyz/models/vision?source=qa'
  ```

- [x] Confirm there is one redirect to:
  `https://llmcatalog.dev/models/vision?source=qa`.
- [x] Check at least ten important URLs from the old sitemap.
- [x] Confirm no important URL redirects to the new home page unless the old
  URL was the old home page.
- [x] Confirm that `www.llmdb.xyz` returns one `308` redirect and preserves the
  path and query string.

### 7.4 MCP checks

- [x] New-domain MCP request returns `200`:

  ```sh
  curl -fsS https://llmcatalog.dev/api/mcp \
    -H 'content-type: application/json' \
    --data '{"method":"tools/list"}'
  ```

- [x] Old-domain MCP request returns `200` and does not redirect:

  ```sh
  curl -fsS https://llmdb.xyz/api/mcp \
    -H 'content-type: application/json' \
    --data '{"method":"tools/list"}'
  ```

- [x] Confirm that the old-domain response has no `Location` header.
- [ ] Test one configured MCP client with the new endpoint.
- [ ] Test one existing client with the old endpoint.

### 7.5 Analytics and logs

- [x] Confirm Plausible shows a live visit for `llmcatalog.dev`.
- [x] Confirm Plausible accepts a custom filter event.
- [x] Confirm `/_q/s.js` loads.
- [x] Change the Plausible site domain. The event endpoint returns `202`
  without `x-plausible-dropped` for `llmcatalog.dev` events.
- [x] Check Fly logs for host, redirect, WebSocket, MCP, and application errors:

  ```sh
  fly logs -a llmdb-prod
  ```

- [ ] Check Cloudflare analytics for a large number of 4xx, 5xx, or redirect
  responses.

## Phase 8: Search migration

Complete this phase after the site and redirects have been stable for at least
24 hours.

Reference: [Google site moves](https://developers.google.com/search/docs/crawling-indexing/site-move-with-url-changes)
and [Google Change of Address](https://support.google.com/webmasters/answer/9370220?hl=en).

- [ ] Inspect the new home page, About page, major landing pages, and one model
  page with Search Console URL Inspection.
- [ ] Confirm that Google can fetch the pages.
- [ ] Confirm that the selected canonical URL is on `llmcatalog.dev`.
- [ ] Submit `https://llmcatalog.dev/sitemap.xml` in the new property.
- [ ] Open the `llmdb.xyz` property.
- [ ] Submit Change of Address from `llmdb.xyz` to `llmcatalog.dev`.
- [ ] Record the submission time: ____________________
- [ ] Record the Search Console confirmation or task URL:
  ____________________
- [ ] Keep old-domain redirects active for at least one year. Do not create
  redirect chains.
- [ ] Expect temporary search traffic changes while Google processes the move.

### Bing Webmaster Tools

- [ ] Import or add `llmcatalog.dev` in Bing Webmaster Tools.
- [ ] Verify the new site.
- [ ] Submit `https://llmcatalog.dev/sitemap.xml`.
- [ ] Inspect the new home page and major landing pages.
- [ ] Use IndexNow or URL submission only if it is useful for the current
  indexing workflow.

Reference: [Bing site setup](https://www.bing.com/webmasters/help/getting-started-checklist-66a806de)
and [Bing sitemaps](https://www.bing.com/webmasters/help/Sitemaps-3b5cf6ed).

## Phase 9: Monitor after launch

### First 24 hours

- [ ] Check Fly health and logs after 15 minutes, one hour, four hours, and 24
  hours.
- [ ] Check Cloudflare error rates and redirect counts.
- [ ] Check Plausible real-time and daily totals.
- [ ] Check old-domain MCP requests.
- [ ] Fix any internal link that still uses `llmdb.xyz`.

### First four weeks

- [ ] Review Search Console pages, indexing, crawl, and performance each week.
- [ ] Review the old and new sitemap state each week.
- [ ] Review 404 and 5xx URLs each week.
- [ ] Compare new-domain traffic with the recorded baseline.
- [ ] Update important external links that still use the old domain.
- [ ] Check certificate renewal state in Fly and Cloudflare.

### After three months

- [ ] Confirm most indexed URLs use `llmcatalog.dev`.
- [ ] Confirm old-domain search impressions continue to decrease.
- [ ] Keep redirects and old-domain registration active.
- [ ] Decide whether `POST /api/mcp` legacy support is still required. Prefer to
  keep it if maintenance cost is low.

### After one year

- [ ] Review old-domain traffic before any removal decision.
- [ ] Keep redirects indefinitely if the domains still receive traffic or have
  external links.
- [ ] Do not let `llmdb.xyz` expire while it is still trusted by users or search
  engines.

## Rollback plan

Use rollback if the new domain has TLS failures, redirect loops, major
application failures, broken MCP access, or lost analytics that cannot be fixed
quickly.

- [ ] Pause or disable the Cloudflare old-domain redirect rules.
- [ ] Set the production host secrets back to `llmdb.xyz`:

  ```sh
  fly secrets set \
    PHX_HOST=llmdb.xyz \
    CANONICAL_HOST=llmdb.xyz \
    -a llmdb-prod
  ```

- [ ] Roll back the Fly release only if the code change causes the failure.
- [ ] Confirm `https://llmdb.xyz/` returns `200` again.
- [ ] Confirm old-domain MCP access.
- [ ] If the Plausible change is within its transition period, change the site
  domain back and confirm event delivery.
- [ ] If Change of Address was submitted, use Search Console to cancel it.
- [ ] Keep the new DNS records and certificates while the problem is fixed.
  Do not delete them during an incident.
- [ ] Record the failure, action, and result:

  ```text
  Failure:
  Start time:
  Rollback decision:
  Actions:
  Result:
  Follow-up issue:
  ```

## Final completion record

- [x] Code changes merged
- [x] Production deployment complete
- [x] Cloudflare zone active
- [x] Fly certificates valid
- [x] Redirects active and tested
- [x] MCP compatibility tested
- [ ] Plausible migrated and tested
- [ ] Google Search Console Change of Address submitted
- [ ] New sitemap submitted to Google
- [ ] New sitemap submitted to Bing
- [ ] External profiles and documentation updated
- [x] Monitoring owner assigned: Mike Hostetler
- [ ] Rollback window closed

Final notes:

```text
Technical cutover: 2026-08-12 13:16 UTC
Final code image: llmdb-prod:deployment-01KZV26891BPS6FCTTR4CJP6RK
Final machine version: 101
Known follow-up work: Change the Plausible site domain. After 24 hours of
stable redirects, add the new Search Console property, submit the sitemap, and
submit Change of Address. Complete Bing, DNSSEC, profile, and documentation
updates as required.
Open issues: Plausible drops llmcatalog.dev events until the authenticated site
owner changes the configured domain.
```
