<!--- Security > SP Configuration test index --->
<cfoutput>
<h2>Security &gt; SP Configuration</h2>

<h3>Add / generate sync tests</h3>
<ul>
	<li><a href="addSp.cfm">Add SP</a> — alias <code>ccsTestSpAdd</code></li>
	<!--- <li><a href="generateSp.cfm">Generate SP</a> — alias <code>ccsTestSpGen</code></li> --->
</ul>

<h3>Form field sync tests</h3>
<ul>
	<li><a href="spName.cfm">Name</a> — rename <code>ccsTestSpFields</code> / <code>ccsTestSpFieldsRenamed</code></li>
	<li><a href="spDescription.cfm">Description</a> — toggle test description text</li>
	<li><a href="spIdpInitiatedSso.cfm">IdP Initiated SSO</a> — toggle enabled / disabled</li>
	<li><a href="spEntityId.cfm">Entity Id</a> — toggle default / alternate test entity id</li>
	<li><a href="spAcsUrl.cfm">ACS URL</a> — toggle default / alternate ACS URL</li>
	<li><a href="spAcsBinding.cfm">ACS Binding</a> — toggle <code>redirect</code> / <code>post</code></li>
	<li><a href="spSloUrl.cfm">SLO URL</a> — toggle empty / alternate test SLO URL</li>
	<li><a href="spSloBinding.cfm">SLO Binding</a> — toggle empty / <code>redirect</code></li>
	<li><a href="spSignRequests.cfm">Sign Requests</a> — toggle enabled / disabled</li>
	<li><a href="spWantAssertionsSigned.cfm">Want Assertions Signed</a> — toggle enabled / disabled</li>
	<li><a href="spLogoutResponseSigned.cfm">Logout Response Signed</a> — toggle enabled / disabled</li>
	<li><a href="spSignKeystorePath.cfm">Signing Keystore Path</a> — toggle empty / alternate test path</li>
	<li><a href="spSignKeystorePassword.cfm">Signing Keystore Password</a> — toggle empty / test password</li>
	<li><a href="spSignKeystoreAlias.cfm">Signing Keystore Alias</a> — toggle empty / test alias</li>
	<li><a href="spRequestStore.cfm">Request Store</a> — toggle <code>Default</code> / <code>Cache</code></li>
</ul>

<p><em>Add/generate tests create dedicated CCS test Service Providers through the Admin API. Field tests seed <code>ccsTestSpFields</code> and update individual form settings via <code>modifySpMetadata</code>. Existing administrator SPs such as <code>okta_sp</code>, <code>sp_add</code>, and <code>CFGenerated_*</code> are not modified. Each test removes its test SP(s) in the <code>finally</code> block via <code>restoreSecuritySyncTest</code>.</em></p>
</cfoutput>
