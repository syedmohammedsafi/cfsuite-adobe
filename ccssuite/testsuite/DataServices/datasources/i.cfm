<h2>Data &amp; Services - Data Sources</h2>
<p>Run registration tests only on disposable CCS instances. Only reserved loopback datasource fixtures are created and removed.</p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
                <tr><td>Driver</td><td>driver</td><td>select-one</td><td><a href="driver.cfm">driver.cfm</a></td></tr>
                <tr><td>Data list: Actions | Data Source Name | Driver | Status</td><td></td><td>data list</td><td><a href="datasourceList.cfm">datasourceList.cfm</a> (read-only)</td></tr>
        </tbody>
</table>
<h3><a href="apacheDerbyClient/i.cfm">Add: Apache Derby Client</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="apacheDerbyClient/dsn.cfm">apacheDerbyClient/dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="apacheDerbyClient/database.cfm">apacheDerbyClient/database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="apacheDerbyClient/host.cfm">apacheDerbyClient/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="apacheDerbyClient/port.cfm">apacheDerbyClient/port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="apacheDerbyClient/username.cfm">apacheDerbyClient/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="apacheDerbyClient/password.cfm">apacheDerbyClient/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="apacheDerbyClient/description.cfm">apacheDerbyClient/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="apacheDerbyEmbedded/i.cfm">Add: Apache Derby Embedded</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="apacheDerbyEmbedded/dsn.cfm">apacheDerbyEmbedded/dsn.cfm</a></td></tr>
                <tr><td>Database Folder</td><td>database</td><td>text</td><td><a href="apacheDerbyEmbedded/database.cfm">apacheDerbyEmbedded/database.cfm</a></td></tr>
                <tr><td>Create Database</td><td>isnewdb</td><td>checkbox</td><td><a href="apacheDerbyEmbedded/createDatabase.cfm">apacheDerbyEmbedded/createDatabase.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="apacheDerbyEmbedded/description.cfm">apacheDerbyEmbedded/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="db2/i.cfm">Add: DB2 Universal Database</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="db2/dsn.cfm">db2/dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="db2/database.cfm">db2/database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="db2/host.cfm">db2/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="db2/port.cfm">db2/port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="db2/username.cfm">db2/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="db2/password.cfm">db2/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="db2/description.cfm">db2/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="jndi/i.cfm">Add: J2EE Datasource (JNDI)</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="jndi/dsn.cfm">jndi/dsn.cfm</a></td></tr>
                <tr><td>JNDI Name</td><td>jndiname</td><td>text</td><td><a href="jndi/jndiname.cfm">jndi/jndiname.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="jndi/username.cfm">jndi/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="jndi/password.cfm">jndi/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="jndi/description.cfm">jndi/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="msAccess/i.cfm">Add: Microsoft Access</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal API ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>name</td><td>text</td><td><a href="msAccess/dsn.cfm">msAccess/dsn.cfm</a></td></tr>
                <tr><td>Database File</td><td>databasefile</td><td>text</td><td><a href="msAccess/databaseFile.cfm">msAccess/databaseFile.cfm</a></td></tr>
                <tr><td>System Database File</td><td>systemDatabaseFile</td><td>text</td><td><a href="msAccess/systemDatabaseFile.cfm">msAccess/systemDatabaseFile.cfm</a></td></tr>
                <tr><td>Use Default User name</td><td>UseTrustedConnection</td><td>checkbox</td><td><a href="msAccess/useDefaultUsername.cfm">msAccess/useDefaultUsername.cfm</a></td></tr>
                <tr><td>ColdFusion User Name</td><td>username</td><td>text</td><td><a href="msAccess/username.cfm">msAccess/username.cfm</a></td></tr>
                <tr><td>ColdFusion Password</td><td>password</td><td>password</td><td><a href="msAccess/password.cfm">msAccess/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="msAccess/description.cfm">msAccess/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="mssql/i.cfm">Add: Microsoft SQL Server</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="mssql/dsn.cfm">mssql/dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="mssql/database.cfm">mssql/database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="mssql/host.cfm">mssql/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="mssql/port.cfm">mssql/port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="mssql/username.cfm">mssql/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="mssql/password.cfm">mssql/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="mssql/description.cfm">mssql/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="mysql/i.cfm">Add: MySQL</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="mysql/dsn.cfm">mysql/dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="mysql/database.cfm">mysql/database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="mysql/host.cfm">mysql/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="mysql/port.cfm">mysql/port.cfm</a></td></tr>
                <tr><td>Username</td><td>username</td><td>text</td><td><a href="mysql/username.cfm">mysql/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="mysql/password.cfm">mysql/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="mysql/description.cfm">mysql/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="mysqlDataDirect/i.cfm">Add: MySQL (DataDirect)</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="mysqlDataDirect/dsn.cfm">mysqlDataDirect/dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="mysqlDataDirect/database.cfm">mysqlDataDirect/database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="mysqlDataDirect/host.cfm">mysqlDataDirect/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="mysqlDataDirect/port.cfm">mysqlDataDirect/port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="mysqlDataDirect/username.cfm">mysqlDataDirect/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="mysqlDataDirect/password.cfm">mysqlDataDirect/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="mysqlDataDirect/description.cfm">mysqlDataDirect/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="odbcSocket/i.cfm">Add: ODBC Socket</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="odbcSocket/dsn.cfm">odbcSocket/dsn.cfm</a></td></tr>
                <tr><td>ODBC DSN</td><td>datasource</td><td>select-one</td><td><a href="odbcSocket/datasource.cfm">odbcSocket/datasource.cfm</a></td></tr>
                <tr><td>Trusted Connection</td><td>UseTrustedConnection</td><td>checkbox</td><td><a href="odbcSocket/trustedConnection.cfm">odbcSocket/trustedConnection.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="odbcSocket/username.cfm">odbcSocket/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="odbcSocket/password.cfm">odbcSocket/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="odbcSocket/description.cfm">odbcSocket/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="oracle/i.cfm">Add: Oracle</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="oracle/dsn.cfm">oracle/dsn.cfm</a></td></tr>
                <tr><td>SID Name</td><td>sid</td><td>text</td><td><a href="oracle/sid.cfm">oracle/sid.cfm</a></td></tr>
                <tr><td>Service Name</td><td>servicename</td><td>text</td><td><a href="oracle/serviceName.cfm">oracle/serviceName.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="oracle/host.cfm">oracle/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="oracle/port.cfm">oracle/port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="oracle/username.cfm">oracle/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="oracle/password.cfm">oracle/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="oracle/description.cfm">oracle/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="other/i.cfm">Add: Other JDBC Driver</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="other/dsn.cfm">other/dsn.cfm</a></td></tr>
                <tr><td>JDBC URL</td><td>url</td><td>textarea</td><td><a href="other/jdbcUrl.cfm">other/jdbcUrl.cfm</a></td></tr>
                <tr><td>Driver Class</td><td>class</td><td>text</td><td><a href="other/driverClass.cfm">other/driverClass.cfm</a></td></tr>
                <tr><td>Driver Name</td><td>driver</td><td>text</td><td><a href="other/driverName.cfm">other/driverName.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="other/username.cfm">other/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="other/password.cfm">other/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="other/description.cfm">other/description.cfm</a></td></tr>
        </tbody>
</table>
<h3><a href="postgresql/i.cfm">Add: PostgreSQL</a></h3>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="postgresql/dsn.cfm">postgresql/dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="postgresql/database.cfm">postgresql/database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="postgresql/host.cfm">postgresql/host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="postgresql/port.cfm">postgresql/port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="postgresql/username.cfm">postgresql/username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="postgresql/password.cfm">postgresql/password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="postgresql/description.cfm">postgresql/description.cfm</a></td></tr>
        </tbody>
</table>
<p><a href="_validate.cfm">_validate.cfm</a> - read-only API, comparison, and safety validation.</p>
<p>The registration cases retain strict CCS expectations even when the fields currently do not synchronize.</p>