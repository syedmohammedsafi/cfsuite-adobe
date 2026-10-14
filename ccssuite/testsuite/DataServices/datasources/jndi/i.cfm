<h2>Data Sources - Add: J2EE Datasource (JNDI)</h2>
<p>Run only on disposable CCS instances. Each case captures original node state, prepares a reserved baseline, changes its selected field, and restores datasource registrations.</p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
                <tr><td>JNDI Name</td><td>jndiname</td><td>text</td><td><a href="jndiname.cfm">jndiname.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="username.cfm">username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="password.cfm">password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
        </tbody>
</table>
<p>Only reserved CCSSUITE_JNDI_ datasource and java:comp/env/jdbc/CCSSUITE_JNDI_ resource names are accepted. Passwords are encrypted and their display is redacted.</p>
<p>Required container-managed javax.sql.DataSource bindings must exist before running a case. A lookup-only preflight checks the reserved names before any Administrator write. The suite never binds or unbinds resources.</p>
<p>The JNDI Name case requires both its original resource and the _UPDATED resource. Missing bindings are setup failures, not CCS failures or passing tests.</p>
<p>CCS expectations remain strict. Original state is separate from Prepared baseline, and missing peers remain Not registered.</p>
<p><a href="../i.cfm">Data Sources</a> | <a href="../_validate.cfm">Read-only validation</a></p>