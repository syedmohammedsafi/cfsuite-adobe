# Scheduled Tasks Tests

Open `i.cfm` for the Schedule New Task creation test and 39 task-field cases.
Each case has its own thin CFM page and uses the shared test runner.
Related form controls
are mapped to the same Scheduler API property: hours/minutes/seconds become
an interval in seconds, scheduling radios choose the frequency, and the
different start-time inputs all update `Starttime`.

The suite uses `CFIDE.adminapi.scheduler.updateTask(ScheduleTagTO)`, not
individual field setter calls on the Administrator API. `getTasks()` finds
reserved tasks and `findTask(task, group, "server")` reads their fields.

## CCS Regression Expectations

These are normal synchronization regression tests, not expected-failure tests.
Only the prime node is updated during the assertion phase; peers must receive
the task through CCS. Unchanged or missing peer tasks fail the test. There is
no scheduler-specific tolerance or manual peer propagation to make a broken
release pass.

The creation case starts from an empty reserved slot. Field cases first require
fixture creation to synchronize, then change the selected field and require
that change to synchronize. If Adobe fixes scheduled-task replication, the
same cases can pass without changing their expected results. Direct per-node
writes are used only for cleanup/restoration.

## Fixture Safety

- Deploy the updated suite and utilities to every participating CCS node.
  A shared getter returning HTTP 200 with an empty body indicates missing
  scheduler support, not an empty task list. Each node's
  `/cfsuite/ccssuite/testsuite/serverSettings/_getter.cfm?setting=task&area=scheduledTasks`
  must return a JSON array (`[]` when no reserved fixture exists).
  Empty, malformed, or non-array baselines stop the test before task writes.
- Use disposable CCS instances only; test pages modify live configuration.
- Only `ccssuite_scheduler_<field>` tasks in `CCSSUITE_SCHEDULER` or
  `CCSSUITE_SCHEDULER_ALT` are owned by these tests. Rename and chaining
  cases also reserve `_renamed` and `_child` task names.
- A preexisting reserved fixture on any node stops the test before writes.
- Fixtures are paused and start in 2099. Their URLs use loopback port 1.
  No run, pause-all, or resume-all operations are performed on existing jobs.
- `updateTask()` does not preserve the transfer object's paused status on
  the installed runtime. Each reserved fixture is explicitly paused after
  creation or update, before readback comparison.
- The fixture event handler vetoes execution. Output settings use reserved
  filenames under the instance logs directory; tests do not execute tasks
  or create output files.
- A fixture is created before the field update. Failure to synchronize the
  fixture prevents the field update. `cffinally` restores the original
  per-node state and removes reserved tasks, including the chained child.
- Password snapshots are SHA-256 digests; plaintext readbacks are not displayed.
- `_validate.cfm` constructs every fixture transfer object and verifies
  field comparisons without creating tasks or changing configuration.

## Cluster Setup

`setClusterDsnName(dsname, createtables)` takes a datasource name and a boolean,
not a separate call per form field.

`dsnname.cfm` lists configured datasource names and requires confirmation
that the selected datasource and participating instances are disposable.
The datasource must already have compatible scheduler tables on every
participating node. The test passes `false` for table creation, then restores
each original DSN or calls `disableCluster()` if clustering was originally
disabled. The existing `?testDsn=DISPOSABLE_SCHEDULER_DSN` invocation remains
available for operators who have already approved that target.

The Clustered field runs as a normal CCS regression, changing the paused
fixture's `Clustered` value from false to true. It does not preemptively skip
when the scheduler cluster DSN is empty, configure a datasource, or create
tables. The Scheduler API must accept the update and CCS must replicate it
for the test to pass. If the installed runtime requires cluster setup to
accept the field, that rejection remains a test error rather than a skip.

`createTables.cfm` now provides the same datasource selection form. It does
not execute on GET or on an unconfirmed POST. After explicit confirmation,
it calls `setClusterDsnName(dsname, true)` on the current node, then verifies
the selected scheduler datasource through the shared CCS test runner.
The original per-node scheduler DSNs are restored on success or failure.
Database table creation/replacement is NOT undone by that restoration;
schema changes are retained and require separate database cleanup. Use only
an explicitly approved disposable database. Table creation is performed on
one node, not repeated on every peer.

Live `updateTask`, CCS replication, and rollback must be verified on confirmed
disposable instances. Read-only fixture validation does not prove those paths.