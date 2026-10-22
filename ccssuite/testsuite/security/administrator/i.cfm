<!--- Security > Administrator test index - covers security/cfadminpassword.cfm (all 27 fields) --->
<cfoutput>
<h2>Security &gt; Administrator (security/cfadminpassword.cfm)</h2>
<p><a href="../i.cfm">&larr; Security Tests</a></p>

<h3>1. Authentication Mode (AdminAuth)</h3>
<ul>
	<li><a href="adminSinglePasswordOnly.cfm">Use a single password only (default)</a> — Single password authentication</li>
	<li><a href="adminSeparateUserAuth.cfm">Separate user name and password authentication</a> — Multi-user authentication</li>
	<li><a href="adminNoAuth.cfm">No authentication needed</a> — Open authentication (not recommended)</li>
</ul>

<h3>2. Password &amp; Seed Management</h3>
<ul>
	<li><a href="adminOldPassword.cfm">Old Password (cfadmin_oldpassword)</a> — Verification via checkAdminPassword()</li>
	<li><a href="adminNewPassword.cfm">New Password (cfadmin_Newpassword)</a> — Application via setAdminPassword()</li>
	<li><a href="adminNewPasswordConfirm.cfm">Confirm Password (cfadmin_NewpasswordConfirm)</a> — Match/mismatch validation</li>
	<li><a href="seed.cfm">New Seed (seed)</a> — Server encryption seed via setSeed()</li>
</ul>

<h3>3. Session Management</h3>
<ul>
	<li><a href="allowConcurrentAdminLogin.cfm">Allow concurrent login sessions (allowconclogin)</a> — Administrator console concurrency toggle</li>
</ul>

<h3>4. External Authentication (ExtAuth)</h3>
<ul>
	<li><a href="externalAuthNone.cfm">External Authentication — NONE</a></li>
	<li><a href="externalAuthSaml.cfm">External Authentication — SAML</a></li>
	<li><a href="samlIdentityProvider.cfm">Identity Provider (samlIDP)</a></li>
	<li><a href="samlServiceProvider.cfm">Service Provider (samlSP)</a></li>
	<li><a href="samlGroupName.cfm">SAML groupName alias (samlGroup)</a></li>
	<li><a href="externalAuthLdap.cfm">External Authentication — LDAP</a></li>
</ul>

<h3>5. LDAP Configuration</h3>
<ul>
	<li><a href="ldapHost.cfm">Host (ldap_host)</a></li>
	<li><a href="ldapTcpPort.cfm">TCP Port (ldap_tcp_port)</a></li>
	<li><a href="ldapUserBindDN.cfm">User Bind DN (ldap_bindDN)</a></li>
	<li><a href="ldapUserBindPassword.cfm">User Bind Password (ldap_bindPass)</a></li>
	<li><a href="ldapUserBaseContext.cfm">User BaseContext (ldap_userBaseContext)</a></li>
	<li><a href="ldapGroupBaseContext.cfm">Group BaseContext (ldap_groupBaseContext)</a></li>
	<li><a href="ldapTimeout.cfm">Server Timeout (ldap_timeout)</a></li>
	<li><a href="ldapSslEnabled.cfm">SSL/TLS (ldap_ssl)</a></li>
	<li><a href="ldapStartTls.cfm">Start TLS (ldap_startTLS)</a></li>
	<li><a href="ldapUserConfig.cfm">User Configuration (ldap_userConfig[])</a></li>
	<li><a href="ldapUsernameAttr.cfm">Username Attribute (ldap_usernameAttr)</a></li>
	<li><a href="ldapGroupConfig.cfm">Group Configuration (ldap_groupConfig[])</a></li>
	<li><a href="ldapGroupnameAttr.cfm">Groupname Attribute (ldap_groupnameAttr)</a></li>
</ul>
</cfoutput>