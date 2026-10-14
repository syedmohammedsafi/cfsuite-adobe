---
name: ccssuite
description: Work with ccssuite, the CF Administrator multi-node CCS (Central Config Server) sync test suite. Use when adding a new setting sync test, editing/debugging a testsuite/**/*.cfm test, touching testDriver.cfc/testManager.cfc/ccsDriver.cfc/serverSettingsTestUtil.cfc, or running a test against local CF instances (ports 8500-8502).
---

# ccssuite concept

ccssuite proves CF Administrator settings replicate correctly through CCS across a
multi-node cluster: set a value on one "prime" node, read it back on every node, and
assert the sync matches what should have happened (including the cases where sync is
known to NOT happen, e.g. per-instance paths).

## Architecture (read in this order for a new area)

- `constants.cfc` / `testConstants.cfc` — key names for CCS_CONFIG struct and the
  TEST_FRAME struct shape (PRIME_SET, NONPRIME_SET, PRESET_VALUE, POSTSET_VALUE, SETTER_URL, GETTER_URL, ...).
- `ccsDriver.cfc` — proxies `coldfusion.centralconfig.server.CentralConfigServerManager`
  (Java) to list CCS nodes; falls back to `lib/ccs/nodes.properties` when Java access is blocked.
- `testManager.cfc` — turns the node list into prime/non-prime node keys by cluster+environment.
- `testDriver.cfc` — the actual test engine: builds a test frame, sets the value on the
  prime node (local Admin API call or HTTP to a peer), reads it back everywhere,
  compares actual vs expected (`valuesMatch`), and rolls back to the preset value on
  failure or in `<cffinally>`.
- `utils/serverSettingsTestUtil.cfc` — shared helpers for serverSettings-style test
  pages: `initTestFrame`, `runMultiNodeBooleanSyncTest`/`runMultiNodeDocumentSyncTest`,
  value-flipping helpers per setting name (`flipBooleanValue`, `bumpNumeric`, `alternate*`, `toggle*`).
- `utils/*ConfigUtil.cfc` (one per API area: security, LLM, vectorstore, MCP, IDP, SP,
  event gateways, extensions, allowed IPs, ...) — area-specific `configsMatch`/
  `*ValuesMatch` because plain string equality doesn't hold (encrypted-on-write fields,
  base64 JSON blobs, per-instance paths, unpredictable CCS replication timing for
  mail/restServices).
- `testsuite/<area>/_getter.cfm` + `_setter.cfm` — thin HTTP endpoints the driver calls
  on peer nodes; they call `utils/serverSettingsApiUtil.cfc` (or the area's own API util)
  to read/write the Admin API locally on that node.
- `testsuite/<area>/<feature>/<settingName>.cfm` — the actual test page: instantiate
  `testDriver`, call the matching `*TestUtil` run-helper, emit a `<cf_qatest>` block.

## Adding a new setting sync test

1. Find the area's existing `_getter.cfm`/`_setter.cfm` and API util (or add one if the
   area is new) — this is where the actual Admin API read/write for that setting lives.
2. Add a test `.cfm` under `testsuite/<area>/<feature>/` modeled on a sibling in the same
   directory (e.g. `testsuite/serverSettings/settings/enableNullSupport.cfm`): build via
   `testDriver`, call the area's `*TestUtil` sync-test helper with the setting name and
   `CGI.SCRIPT_NAME`, emit `<cf_qatest>` / `<cf_qatestEnd stats=true>`, restore in `<cffinally>`.
3. If the setting needs a non-trivial "next value" (not a plain boolean flip or numeric
   bump), add a `case` to `serverSettingsTestUtil.getNewSetValueForSetting()` (or the
   area-specific util's equivalent) rather than hardcoding logic in the test page.
4. If comparing actual-vs-expected needs special handling (encrypted field, JSON blob,
   per-instance value that must NOT be expected to sync), add/extend the area's
   `*ConfigUtil.configsMatch` / `*ValuesMatch`, wired in `testDriver.valuesMatch()`.

## Gotchas already discovered (don't re-derive, extend instead)

- Mail settings and REST Services (`neo-jaxrs.xml`) replicate via CCS on an
  unpredictable schedule — comparisons for these tolerate "unchanged from preset" as a
  passing peer state, not just the new value.
- Solr Server's password and Admin LDAP bind password are auto-encrypted on write —
  never compare peer readback against the plaintext value.
- REST Services registration is a per-instance filesystem path — deliberately never
  expected to sync to peers at all (`isInstanceLocalApiArea`).
- Security-menu settings (`administrator,rds,sandboxsecurity,secureprofile,...`) always
  go through `setAndVerifySettingViaHttp` (push-and-verify-with-retry), never a
  single-shot HTTP push, because CCS's own organic replication can reassert a stale
  value moments after a plain push lands.

## Running/debugging a test

Each CF instance under test serves the same ccssuite app on its own port (this repo's
`.claude/settings.local.json` shows 8500/8501/8502). Hit a test page or its
`_getter.cfm`/`_setter.cfm` directly with `curl` to isolate driver logic from the
Admin-API/CCS layer, e.g.:

```
curl -s "http://localhost:8500/cfsuite/ccssuite/testsuite/<area>/_getter.cfm?setting=<Name>&area=<apiArea>"
```

`?reinit=1` on a test page forces `appBootstrap` to reinitialize CCS node config for
that request — use it after changing `constants.cfc` or node topology.
