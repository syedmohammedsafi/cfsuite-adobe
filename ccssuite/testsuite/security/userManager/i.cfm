<!--- Security > User Manager test index --->
<cfoutput>
<h2>Security &gt; User Manager</h2>

<h3>Sync tests</h3>
<ul>
	<li><a href="addTestUser.cfm">Add test user</a> — create/delete <code>ccsTestUserMgr</code></li>
	<li><a href="userDescription.cfm">User description</a></li>
	<li><a href="allowRdsAccess.cfm">Allow RDS access</a></li>
	<li><a href="allowAdminAccess.cfm">Allow administrative access</a></li>
	<li><a href="enabledDataSource.cfm">Allowed data source</a> — <code>cfbookclub</code></li>
	<li><a href="userRole.cfm">Allowed role</a> — <code>AI Services &gt; LLMs</code></li>
	<li><a href="securedFilePath.cfm">Secured file path</a> — per-instance path under <code>_ccsUserTest</code></li>
	<li><a href="isGroup.cfm">Group</a> — confirmed independent of LDAP/SAML config, unlike the other identity-related fields below</li>
</ul>

<h3>Not in testsuite</h3>
<table border="1" cellpadding="6" cellspacing="0">
	<tr><th>Setting</th><th>Reason</th></tr>
	<tr><td>Administrator access level (Console &amp; API vs API only)</td><td><code>allowadminapiaccess</code> does not change observable <code>getUser()</code> roles in CF2025</td></tr>
	<tr><td>Prohibited roles</td><td><code>disabledroles</code> is not returned by <code>getUser()</code></td></tr>
	<tr><td>Prohibited data sources</td><td>Confirmed live, same as prohibited roles: <code>disabledds</code> is not returned by <code>getUser()</code> either</td></tr>
	<tr><td>External User / LDAP / SAML</td><td>Confirmed live: <code>setUser(isLdap=true)</code> (and, by the same identity-source pattern, <code>isSaml</code>) throws an unrecoverable error without a real external LDAP/SAML source configured -- unlike <code>isGroup</code>, which round-trips fine on its own</td></tr>
	<tr><td>User password</td><td>Password hash/salt does not sync across nodes</td></tr>
	<tr><td>Secured file permissions via Admin API</td><td><code>setUser(filepermissions=...)</code> throws in CF2025; tests write <code>AuthorizedUsers.sandboxes</code> in neo-security.xml</td></tr>
</table>

<p><em>Prerequisite: tests enable <strong>Separate user name and password authentication</strong> (Administrator tab) when needed. Each test restores its toggled value in the <code>finally</code> block. The add-user test removes <code>ccsTestUserMgr</code> when restoring to absent.</em></p>
</cfoutput>
