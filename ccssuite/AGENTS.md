# CCS Suite Agent Guidance

## Start Here

- This is an Adobe ColdFusion Administrator multi-node Central Config Server (CCS) synchronization test suite, not a standalone web application.
- Before adding or debugging sync tests, changing the driver/utilities, or running local CF tests, read the [ccssuite skill](.claude/skills/ccssuite/SKILL.md). It documents the architecture, test workflow, comparison exceptions, and reinitialization behavior.

## Change Boundaries

- Keep test pages thin. Follow a sibling in the same area; [timeoutRequestTimeLimit.cfm](testsuite/serverSettings/settings/timeoutRequestTimeLimit.cfm) demonstrates the shared helper, `cf_qatest` output, and `cffinally` restoration pattern.
- Put setting reads/writes in the area's API utility, next-value selection in its test utility, and special comparisons in its configuration utility. Do not duplicate these decisions in individual test pages.
- Preserve the driver contract and constant-defined test-frame keys. See [testDriver.cfc](testDriver.cfc), [testManager.cfc](testManager.cfc), and [testConstants.cfc](testConstants.cfc) before changing shared behavior.
- Preserve non-synchronizing, encrypted, and instance-local setting exceptions described in the skill; plain equality is not a universal comparison rule.
- Keep runtime/setup probes separate from regression tests. Do not treat root-level probe pages as established test templates.

## Validation And Safety

- Tests and `_setter.cfm` endpoints modify live Administrator configuration across nodes. Confirm the target instances are disposable test instances before executing writes, and preserve restoration in `cffinally` even on failure.
- Use an existing local ColdFusion instance serving this application at `/cfsuite/ccssuite/`; the documented local ports are 8500-8502. Confirm connectivity and CCS membership instead of assuming every instance is available.
- On Windows PowerShell, use `curl.exe` for curl syntax. A focused test invocation, after confirming the target, is:

  ```powershell
  curl.exe -sS "http://localhost:8500/cfsuite/ccssuite/testsuite/serverSettings/settings/timeoutRequestTimeLimit.cfm"
  ```

- Inspect the rendered `cf_qatest` results and exception output; HTTP success alone does not prove the test passed. If ColdFusion, the harness, or CCS peers are unavailable, report that runtime behavior remains unverified.
- Use the skill's `?reinit=1` procedure after changes to node topology or constants. Do not rewrite setup, bootstrap, or Docker configuration merely to validate a setting change.
- Keep Administrator credentials out of generated guidance, logs, and responses; reuse the suite's existing authentication helpers.