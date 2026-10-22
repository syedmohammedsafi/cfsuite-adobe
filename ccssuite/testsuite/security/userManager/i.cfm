<!--- Security > User Manager test index --->
<cfoutput>
<h2>Security &gt; User Manager</h2>

<h3>Sync tests</h3>
<ul>
	<li><a href="addTestUser.cfm">Add test user</a> &mdash; create/delete <code>ccsTestUserMgr</code></li>
	<li><a href="userDescription.cfm">User description</a></li>
	<li><a href="allowRdsAccess.cfm">Allow RDS access</a></li>
	<li><a href="allowAdminAccess.cfm">Allow administrative access</a></li>
	<li><a href="userAdminConsoleAndApi.cfm">Administrator Console &amp; API Access</a></li>
	<li><a href="userApiAccessOnly.cfm">API Access Only</a></li>
	<li><a href="enabledDataSource.cfm">Allowed data source</a> &mdash; <code>cfbookclub</code></li>
	<li><a href="userProhibitedDataSource.cfm">Prohibited data source</a></li>
	<li><a href="userRole.cfm">Allowed role</a> &mdash; <code>AI Services &gt; LLMs</code></li>
	<li><a href="userProhibitedRole.cfm">Prohibited role</a></li>
	<li><a href="securedFilePath.cfm">Secured file path</a> &mdash; path under <code>_ccsUserTest</code></li>
	<li><a href="userFileRead.cfm">File permission &mdash; Read</a></li>
	<li><a href="userFileWrite.cfm">File permission &mdash; Write</a></li>
	<li><a href="userFileExecute.cfm">File permission &mdash; Execute</a></li>
	<li><a href="userFileDelete.cfm">File permission &mdash; Delete</a></li>
	<li><a href="isGroup.cfm">Group</a></li>
	<li><a href="userExternal.cfm">External User</a></li>
	<li><a href="userTypeLdap.cfm">User Type: LDAP</a></li>
	<li><a href="userTypeSaml.cfm">User Type: SAML</a></li>
	<li><a href="userPassword.cfm">User password</a></li>
	<li><a href="userPasswordConfirm.cfm">Confirm user password</a></li>
</ul>

<p><em>Prerequisite: tests enable <strong>Separate user name and password authentication</strong> (Administrator tab) when needed. Each test restores its toggled value in the <code>finally</code> block. The add-user test removes <code>ccsTestUserMgr</code> when restoring to absent.</em></p>
</cfoutput>
