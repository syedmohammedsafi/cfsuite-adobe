# Data Sources Tests

Administrator page: `datasources/index.cfm`. Open `i.cfm` for the suite cases:

| Setting / Field Label | Internal ID | Type | Test File |
| --- | --- | --- | --- |
| Data Source Name | dsn | text | dsn.cfm |
| Driver | driver | select-one | driver.cfm |
| Actions, Data Source Name, Driver, Status | | data list | datasourceList.cfm |

## Registration And Sync

The tests use `CFIDE.adminapi.datasource` to register two distinct reserved
datasources. The name case selects SQL Server; the driver case selects MySQL
DataDirect. Both read back the datasource name and driver rather than treating
a successful setter response as a passed test.

The supplied setting inventory marks both fields as not synchronizing.
These remain strict CCS regression tests, consistent with the other new
categories: only the prime node is updated during assertions. A missing or
unchanged peer fails; direct peer propagation is not used to obtain a pass.

## Safety And Restoration

Use disposable instances and deploy the category, `datasourceConfigUtil`,
and shared utility/driver changes to every node before running either case.
The node executing a full test page needs the existing `cf_qatest` and
`cf_qatestEnd` custom-tag harness. Peer getter/setter endpoints and the
read-only validator do not require those tags. A missing custom tag is a
harness/setup error, not a passing datasource test.
Every node must supply a valid baseline. Existing registrations named
`CCSSUITE_DATASOURCE_NAME` or `CCSSUITE_DATASOURCE_DRIVER` abort before writes.

Fixtures use `127.0.0.1:1`, database `ccssuite_fixture`, empty credentials,
disabled pooling, and `validateConnection=false`. They do not connect to a
real database or create database tables. Arbitrary datasource names and
connection parameters are rejected. Cleanup checks a fixed ownership marker,
driver, and loopback URL before deleting a reserved registration.

The test page restores captured per-node originals in `cffinally`; the helper
also attempts restoration when a write raises an exception. Existing
datasources and their credentials are not included in test snapshots.

## Data List

`datasourceList.cfm` validates and displays all four columns without editing
or deleting existing registrations. Actions are marked `Read-only`, and
Status is explicitly `Not verified`. This is column/schema coverage, not
Administrator action-button or database connectivity coverage; it does not
call `verifyDsn` against existing connections. Passwords and connection URLs
are never displayed.

`_validate.cfm` exercises the API, strict snapshot comparisons, malformed and
occupied baseline rejection, and list-column validation without writes.

## Apache Derby Client

Open `apacheDerbyClient/i.cfm` for these field-specific cases:

| Setting / Field Label | Internal ID | Type | Test File |
| --- | --- | --- | --- |
| CF Data Source Name | dsn | text | apacheDerbyClient/dsn.cfm |
| Database | database | text | apacheDerbyClient/database.cfm |
| Server | host | text | apacheDerbyClient/host.cfm |
| Port | port | text | apacheDerbyClient/port.cfm |
| User name | username | text | apacheDerbyClient/username.cfm |
| Password | password | password | apacheDerbyClient/password.cfm |
| Description | description | textarea | apacheDerbyClient/description.cfm |

`derbyClientDatasourceConfigUtil` owns the `setDerbyClient` API calls and
comparisons; the existing datasource abstraction delegates Derby settings to
it. All cases use the Data Services getter/setter endpoints and shared runner.
Only this driver is covered here; other driver-specific forms are not added.

Each case captures empty baselines on all nodes, registers a reserved baseline
on the prime node, then changes only its selected field. The name case uses
`originaldsn` to rename its fixture and checks that the original name is gone.
Same-name cases replace only the owned registration with `deleteDatasource`
followed by `setDerbyClient`; they cover Add-form field persistence rather
than in-place edit behavior. This avoids same-name Admin API updates that
returned an absent registration during validation.
Snapshots contain the seven listed fields plus the driver. Database, host,
and port are read from the JDBC URI with `java.net.URI`, not inferred from
whether the setter succeeded. Missing or unchanged CCS peers fail normally.
Rendered update messages and comparison tables show only the selected field;
full snapshots remain internal to comparison and restoration. Password display
is redacted. `Not registered` means the reserved fixture is absent on that
node, while `(unavailable)` means no usable value was read. These tables do not
list unrelated datasource configurations already present on a node.
Derby comparison tables separate `Original state` (captured on every node
before any test writes), `Prepared baseline` (read after setup), and the
updated value. A datasource created by test setup is never reported as an
originally existing value. Peer baselines are read, not fabricated or manually
seeded; a missing peer fixture remains `Not registered`.

Reserved names begin `CCSSUITE_DERBYCLIENT_`; the name test also reserves its
`_RENAMED` variant. Fixtures use only `127.0.0.1` or `127.0.0.2`, ports 1 or 2,
and fixed test database names. No Derby network server is started, connection
verification is not invoked, and no database/table is created. Cleanup checks
the driver and complete non-secret fixture metadata before deleting either
reserved name. Existing registrations cause preflight failure.

Credentials are synthetic and `encryptpassword=true` is preserved. Password
snapshots expose only a SHA-256 fingerprint of the stored representation.
The password case requires a populated fingerprint different from its seeded
baseline; unchanged or unseeded readback fails. Peer snapshots are compared
with the prime snapshot. This verifies password-setting persistence and CCS
replication, not successful database authentication or plaintext recovery.

Deployment requires the new Derby utility plus the updated parent datasource,
Data Services test, and shared comparison utilities. As with other categories,
full test pages require the `cf_qatest` harness on the executing node.

### Runtime Validation Status

Read-only API, comparison, password-change guard, and baseline checks passed
on ports 8500-8503. Live checks exercised reserved baseline registration,
field changes, rename, and cleanup. Some local round trips passed, but later
registration/rename readback intermittently returned an empty array. The
underlying cause remains unresolved; this is not evidence of a CCS-only
failure. Complete seven-case runtime/CCS validation remains unverified.
One reserved name fixture also reappeared after an earlier successful removal
check. It was removed again through ownership-checked cleanup; fresh final
checks found all seven fixtures absent on all four nodes. Stable long-term
registration/removal behavior remains unverified.

The cases remain strict: absent local registration cannot pass, and missing
peer replication is not tolerated. No expected-failure exception or manual
peer propagation was added. Reserved registrations were removed after each
live check, and no database authentication or schema action was performed.

## Apache Derby Embedded

Open `apacheDerbyEmbedded/i.cfm` for the four basic Add-form fields:

| Setting / Field Label | Internal ID | Type | Test File |
| --- | --- | --- | --- |
| CF Data Source Name | dsn | text | apacheDerbyEmbedded/dsn.cfm |
| Database Folder | database | text | apacheDerbyEmbedded/database.cfm |
| Create Database | isnewdb | checkbox | apacheDerbyEmbedded/createDatabase.cfm |
| Description | description | textarea | apacheDerbyEmbedded/description.cfm |

`derbyEmbeddedDatasourceConfigUtil` owns `setDerbyEmbedded` and
`deleteDatasource` calls. Folder and checkbox readback use the structured
`getDatasources().urlmap.database` and `urlmap.isnewdb` values. The driver is
also checked. The Browse Server button selects the Database Folder; it is not
a separate persisted setting. Collapsed advanced fields are outside this slice.

Cases use the same captured Original state, Prepared baseline, and updated
value reporting as Derby Client. Only the selected field is displayed. The
creation checkbox is shown as Enabled/Disabled. Folder comparisons normalize
only the reserved `testAssets/databases/derbyEmbedded` path suffix across
instance roots; different database folders still fail. Missing or unchanged
CCS peers fail; no direct peer propagation is performed during assertions.

Reserved names begin `CCSSUITE_DERBYEMBEDDED_`; the name case also reserves its
`_RENAMED` variant. Folder paths are generated locally under
`testAssets/databases/derbyEmbedded/<field>/original` (or `database/updated`
for the folder test). Caller-supplied paths are not used in API writes.
Only matching owned fixture metadata can be updated or unregistered. Existing
reserved names or database folders prevent new fixture registration.

Create Database changes `isnewdb` from false to true. It tests persistence and
CCS replication of that flag, not database contents, queries, authentication,
or physical database replication. `pooling=false` and
`validateConnection=false` are supplied and `verifyDsn` is not called, but
the API may still materialize a database at the reserved path. Therefore run
only on disposable instances. Creation against an existing folder is rejected.

Cleanup restores datasource registrations in `cffinally` and on write failure;
it never deletes database directories or files. Any files created by the API
remain for manual inspection/removal after verifying they belong to the test.
Deployment includes the new Embedded utility and updated parent datasource,
test, reporting utilities, and category pages. Full runtime/CCS behavior must
be verified separately from the read-only validator.

## DB2 Universal Database

Open `db2/i.cfm` for the seven visible basic Add-form fields:

| Setting / Field Label | Internal ID | Type | Test File |
| --- | --- | --- | --- |
| CF Data Source Name | dsn | text | db2/dsn.cfm |
| Database | database | text | db2/database.cfm |
| Server | host | text | db2/host.cfm |
| Port | port | text | db2/port.cfm |
| User name | username | text | db2/username.cfm |
| Password | password | password | db2/password.cfm |
| Description | description | textarea | db2/description.cfm |

`db2DatasourceConfigUtil` owns `CFIDE.adminapi.datasource.setDB2` calls,
fixture selection, snapshots, and comparisons. The API driver ID is `DB2`;
the normal Administrator port default is 50000. These fixtures instead use
only `127.0.0.1`/`127.0.0.2`, ports 1/2, fixed test database names, and synthetic
credentials. `pooling=false`, `validateConnection=false`, and
`encryptpassword=true` are supplied. No `verifyDsn`, database query, database
creation, or table-creation operation is invoked.

Only names beginning `CCSSUITE_DB2_` and their fixed `_RENAMED` variant are
accepted. Arbitrary names, hosts, credentials, and incomplete fixture payloads
are rejected. Existing registrations cause preflight failure. Cleanup checks
the driver and complete non-secret fixture metadata before unregistering a
reserved name; unrelated datasources are not edited or deleted.

Each case captures all node originals before writes, registers a prime-only
baseline, and changes its selected field. Name changes use `originaldsn`;
same-name Add-form field changes replace only the verified owned registration.
Database, host, and port readback use the structured datasource URL map.
The shared runner restores original registrations in `cffinally` and also
attempts restoration on write exceptions.

Reports show Original state, Prepared baseline, and updated values, with only
the selected field displayed. Password output is redacted; snapshots contain
only SHA-256 fingerprints of stored password representations. The password
case requires a populated fingerprint changed from its captured baseline,
not plaintext/ciphertext equality. This is configuration persistence and CCS
coverage, not database authentication coverage.

All cases retain strict CCS expectations; absent/unchanged peers fail normally.
Peers are not manually seeded or propagated during assertions. Collapsed
advanced fields are not included. Read-only validation covers all seven
fixtures, field mismatch detection, shared routing, unsafe setter rejection,
password-change guards, and original/prepared reporting. Live DB2 registration
and CCS replication remain unverified until explicitly run on disposable nodes.

## J2EE Datasource (JNDI)

Open `jndi/i.cfm` for the five visible basic Add-form fields:

| Setting / Field Label | Internal ID | Type | Test File |
| --- | --- | --- | --- |
| CF Data Source Name | dsn | text | jndi/dsn.cfm |
| JNDI Name | jndiname | text | jndi/jndiname.cfm |
| User name | username | text | jndi/username.cfm |
| Password | password | password | jndi/password.cfm |
| Description | description | textarea | jndi/description.cfm |

`jndiDatasourceConfigUtil` owns `CFIDE.adminapi.datasource.setJNDI` calls,
fixtures, readback normalization, and comparisons. The API requires `name`
and `jndiname`; its default driver ID is `jndi`. Only parameters supported by
this API are sent: no JDBC pooling, port, host, or validateConnection arguments.

Reserved datasource names begin `CCSSUITE_JNDI_`. Resource names are fixed
`java:comp/env/jdbc/CCSSUITE_JNDI_<field>` values, with an `_UPDATED` variant
for the JNDI Name case. The datasource-name case reserves a `_RENAMED` alias.
Caller-supplied names, credentials, or JNDI environments cannot reach the API.
JNDI resource names and user/description values are compared case-sensitively.

Each case captures all node originals before writes, prepares a prime-only
baseline, then changes its selected field. Original state, Prepared baseline,
and updated values are displayed separately; only the selected field is shown.
Absent peer fixtures remain Not registered. Assertions require actual CCS
replication and do not manually seed or propagate to peers.

Name readback accepts the direct `jndiname` field or structured
`urlmap.jndiname`. A `url` representation is accepted only for the reserved
resource prefix. Missing metadata fails instead of substituting the expected
fixture value. Passwords are synthetic and encrypted; snapshots contain only
SHA-256 fingerprints, and visible output is redacted. The password case checks
that its stored fingerprint changes from a populated baseline; it does not
verify plaintext recovery or successful authentication.

Cleanup restores datasource registrations in `cffinally` and attempts the same
on write exceptions. Only reserved registrations with matching complete
non-secret metadata may be removed. No JNDI binding is created, destroyed,
and `verifyDsn`, `getConnection`, or database queries are not invoked. A
lookup-only preflight resolves the fixed reserved names and verifies that each
is a `javax.sql.DataSource` before any Administrator write. Lookup can
initialize a resource according to its existing container configuration.
The suite does not create mock application-server resources or alter naming
context configuration. Live registration still requires disposable nodes.

### Required JNDI Resources

`setJNDI` registers an existing container-managed datasource; it does not
create a binding. Provide these resources in the runtime naming context of
the node executing the test and any peers expected to use the configuration:

- `java:comp/env/jdbc/CCSSUITE_JNDI_DSN`
- `java:comp/env/jdbc/CCSSUITE_JNDI_JNDINAME`
- `java:comp/env/jdbc/CCSSUITE_JNDI_JNDINAME_UPDATED`
- `java:comp/env/jdbc/CCSSUITE_JNDI_USERNAME`
- `java:comp/env/jdbc/CCSSUITE_JNDI_PASSWORD`
- `java:comp/env/jdbc/CCSSUITE_JNDI_DESCRIPTION`

The JNDI Name test needs both original and updated bindings. Missing or
wrong-type resources raise `CCSTest.JndiResourceUnavailable` before setup
writes start; they are not treated as a passed/skipped CCS assertion. Valid
setter requests also check prerequisites before modifying registrations.
Cleanup with `[]` does not require a binding, so it can still unregister an
owned fixture if its resource later disappears. Provisioning bindings is a
container setup task, not part of this configuration sync suite.

### Local Windows Fixture Setup

The separate [setup_jndi_fixtures.ps1](../../../setup_jndi_fixtures.ps1)
provisioner supports the four local disposable instances on ports 8500-8503.
It uses the installed Derby combined bundle, not an external database or a
mock datasource. From the suite root, inspect the no-write plan first:

```powershell
.\setup_jndi_fixtures.ps1
```

Open **Windows PowerShell as administrator** and run from the suite root:

```powershell
.\setup_jndi_fixtures.ps1 -Apply -ConfirmDisposableInstances
```

This backs up each `runtime/conf/context.xml`, adds the six reserved
resources, copies the installed Derby driver into each node's Tomcat common
classpath, and restarts changed instances. It refuses nonmatching existing
resources, unexpected driver files, and existing unowned database paths.
Existing Administrator datasource registrations are not modified.
Fixtures use isolated databases under each instance's `runtime/ccssuite-jndi`
directory. Database files can be created when a fixture is first used; they
are not removed by test cleanup.

After ColdFusion startup completes, verify the bindings without modifying
Administrator settings:

```powershell
.\setup_jndi_fixtures.ps1 -Verify
```

Verification requires all six names to resolve as `javax.sql.DataSource`
on all four nodes, plus the existing read-only checks. It does not run or
weaken the CCS assertions. To undo container setup, restore each node's
original `context.xml` from the backup directory printed by the provisioner
and restart those services. Keep database files separate from DSN cleanup.

Read-only validation covers five field fixtures, shared routing, unsafe setter
rejection, redaction, password-change guards, case-sensitive resource names,
supported metadata shapes, and original/prepared reporting. This does not
prove live registration, successful connection/authentication, or CCS
replication. Collapsed advanced fields are outside this category.

## Microsoft Access

The [Microsoft Access index](msAccess/i.cfm) contains seven thin field tests:

| Screen field | API parameter | Test |
| --- | --- | --- |
| CF Data Source Name | `name` | [dsn.cfm](msAccess/dsn.cfm) |
| Database File | `databasefile` | [databaseFile.cfm](msAccess/databaseFile.cfm) |
| System Database File | `systemDatabaseFile` | [systemDatabaseFile.cfm](msAccess/systemDatabaseFile.cfm) |
| Use Default User name | `UseTrustedConnection` | [useDefaultUsername.cfm](msAccess/useDefaultUsername.cfm) |
| ColdFusion User Name | `username` | [username.cfm](msAccess/username.cfm) |
| ColdFusion Password | `password` | [password.cfm](msAccess/password.cfm) |
| Description | `description` | [description.cfm](msAccess/description.cfm) |

`msAccessDatasourceConfigUtil` owns these fixtures and calls `setMSAccess`
with driver `MSAccess`. The persisted credentials are set through `username`
and `password`. Using `defaultusername`/`defaultpassword` with `System` and
an empty main password did not populate the readback fields, causing seed
verification and cleanup to fail. Synthetic passwords are encrypted on write, compared through
nonempty changed fingerprints, and displayed only as `[redacted]`.
The checkbox test changes the trusted-connection flag from enabled to
disabled. Other fixtures use explicit credentials with that flag disabled.

Reserved DSNs are `CCSSUITE_MSACCESS_<FIELD>`; the name test also uses
`_RENAMED`. Database and system-database paths are beneath
`testAssets/databases/msAccess/<field>/`, using `original.mdb` and
`original.mdw`. The two file-field targets use `updated.mdb` or `updated.mdw`.
Path comparisons use canonical paths and the reserved instance-relative
suffix, following Derby Embedded. Readback requires actual file and boolean
metadata, directly on the datasource or in its structured `urlmap`. Missing
fields fail; expected values are never substituted for unavailable metadata.

The shared runner captures all nodes' original registrations before preparing
the prime-node fixture. Output keeps Original state, Prepared baseline, and
Updated value separate and projects only the selected field. CCS expectations
remain strict; no peer seeding, pass/skip exception, or manual propagation is
used. Cleanup attempts to unregister only verified owned fixtures and restores
the captured per-node originals, including on exceptions.

An empty-state cleanup also recognizes the exact original faulty seed from
the earlier credential mapping: reserved name, driver, file paths, checkbox,
description, username `System`, and empty password must all match. This
exception is cleanup-only; it cannot authorize overwriting the registration
or bypass the empty-original-baseline requirement.

Run live tests only on disposable Windows nodes with the appropriate Access
ODBC driver and ColdFusion ODBC services. Connection validation is disabled;
the suite does not open a database, query tables, fabricate MDB/MDW files, or
delete database files. If registration requires existing valid Access files,
provision disposable files at the reserved paths first. Browse Server is a
file-selection action, not a separately persisted setting; advanced settings
are outside these seven cases.

The Access Admin API can also affect native ODBC definitions. Administrator
seed registration, full-field readback, and unregistration were verified on
8500 after correcting the credential mapping. Native ODBC cleanup and full
CCS synchronization remain unverified; do not run against shared or production
ODBC configuration.
Read-only validation covers all seven fixtures, full-field comparisons,
malformed payload rejection, metadata shapes, password change guards,
redaction, shared routing, and original-state safety. It does not prove live
registration, native driver connectivity, or CCS replication.