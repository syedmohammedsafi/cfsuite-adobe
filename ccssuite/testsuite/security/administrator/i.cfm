<!--- Security > Administrator test index --->

<cfoutput>

<h2>Security &gt; Administrator</h2>



<h3>Sync tests</h3>

<ul>

	<li><a href="adminSinglePasswordOnly.cfm">ColdFusion Administration Authentication — Single Password Only</a> — Use a single password only (default)</li>

	<li><a href="adminSeparateUserAuth.cfm">ColdFusion Administration Authentication — Separate User Name and Password</a> — Separate user name and password authentication (allows multiple users)</li>

	<li><a href="adminNoAuth.cfm">ColdFusion Administration Authentication — No Authentication</a> — No authentication needed (not recommended)</li>

	<li><a href="allowConcurrentAdminLogin.cfm">Allow concurrent login sessions</a></li>

	<li><a href="externalAuthNone.cfm">External Authentication — NONE</a></li>

	<li><a href="externalAuthSaml.cfm">External Authentication — SAML</a> — reuses the idp_own/okta_sp pairing already configured on this node</li>

	<li><a href="externalAuthLdap.cfm">External Authentication — LDAP</a> — flips the active auth type only; stored LDAP connection details are placeholder/unreachable test data</li>

	<li><a href="ldapHost.cfm">Edit LDAP Configuration — Host</a></li>

	<li><a href="ldapTcpPort.cfm">Edit LDAP Configuration — TCP Port</a></li>

	<li><a href="ldapUserBindDN.cfm">Edit LDAP Configuration — User Bind DN</a></li>

	<!--- <li><a href="ldapUserBindPassword.cfm">Edit LDAP Configuration — User Bind Password</a> — bind password is auto-encrypted on write; verified as "changed to non-empty," not exact match</li> --->

	<li><a href="ldapUserBaseContext.cfm">Edit LDAP Configuration — User BaseContext</a></li>

	<li><a href="ldapGroupBaseContext.cfm">Edit LDAP Configuration — Group BaseContext</a></li>

	<li><a href="ldapSslEnabled.cfm">Edit LDAP Configuration — SSL/TLS</a></li>

	<li><a href="ldapStartTls.cfm">Edit LDAP Configuration — Start TLS</a></li>

	<li><a href="ldapUserConfig.cfm">Edit LDAP Configuration — User Configuration</a></li>

	<li><a href="ldapUsernameAttr.cfm">Edit LDAP Configuration — Username Attribute</a></li>

	<li><a href="ldapGroupConfig.cfm">Edit LDAP Configuration — Group Configuration</a></li>

	<li><a href="ldapGroupnameAttr.cfm">Edit LDAP Configuration — Groupname Attribute</a></li>

</ul>



<h3>SAML field sync tests</h3>

<p>These tests prepare temporary SAML providers and a pairing automatically, including when External Authentication is NONE. During the test, Administrator login temporarily uses SAML. Finally, each node's original authentication mode and saved pairing are restored, and only providers absent before the test are removed. Run on disposable test instances.</p>

<ul>
	<li><a href="samlIdentityProvider.cfm">Identity Provider (samlIDP)</a></li>
	<li><a href="samlServiceProvider.cfm">Service Provider (samlSP)</a></li>
	<li><a href="samlGroupName.cfm">SAML groupName alias (samlGroup)</a></li>
</ul>

<h3>Not automated</h3>

<table border="1" cellpadding="6" cellspacing="0">

	<tr><th>Setting</th><th>Syncs?</th><th>Reason not automated</th></tr>

	<tr><td>Old / New / Confirm Password (cfadmin_oldpassword, cfadmin_Newpassword, cfadmin_NewpasswordConfirm)</td><td>No</td><td>These are inputs to one password-change operation, not three configuration settings. Changing the root password can invalidate suite authentication and prevent restoration; no automatic password changes are performed.</td></tr>

	<tr><td>New Seed (seed)</td><td>No</td><td>Rotates encryption key material. Not a CCS setting toggle; changing it can affect encrypted credentials. No automatic seed changes are performed.</td></tr>

	<tr><td>Root administrator username</td><td>Partial</td><td>No public Admin API setter; sensitive partial sync</td></tr>

	<tr><td>Root administrator password</td><td>No</td><td>Hash/salt per node — does not sync</td></tr>

	<tr><td>Password seed</td><td>No</td><td>Encryption key material — does not sync</td></tr>

	<tr><td>Session / login timeout</td><td>Verify</td><td>No SecurityService getter/setter in CF2025 Admin API</td></tr>

	<tr><td>LDAP Server Timeout</td><td>Blocked (unsafe)</td><td>Confirmed live: changing this value makes setAdminLdapConfiguration() perform an actual blocking LDAP connect attempt bounded by the new timeout (~100+ seconds observed going 120&rarr;125), occupying a request thread that long and briefly making the shared admin console unreachable during testing. Deliberately kept read-only in securityConfigUtil.cfc, unlike the other LDAP fields which don't trigger a live connection.</td></tr>

</table>

</cfoutput>

