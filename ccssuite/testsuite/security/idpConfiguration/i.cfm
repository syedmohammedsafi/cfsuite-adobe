<!--- Security > IDP Configuration test index --->
<cfoutput>
<h2>Security &gt; IDP Configuration</h2>

<h3>Import type sync tests</h3>
<ul>
	<li><a href="addIdpFromSamlUrl.cfm">Import from SAML URL</a> — alias <code>ccsTestIdpUrl</code></li>
	<li><a href="addIdpFromSamlDefinition.cfm">Import from SAML definition</a> — alias <code>ccsTestIdpDef</code></li>
	<li><a href="addIdpFromXmlFile.cfm">Import from local XML file</a> — alias <code>ccsTestIdpXml</code></li>
	<li><a href="addIdpOwnDefinition.cfm">Create own SAML definition</a> — alias <code>ccsTestIdpOwn</code></li>
</ul>

<h3>SAML URL form field sync tests</h3>
<ul>
	<li><a href="idpName.cfm">Name</a> — rename <code>ccsTestIdpFields</code> / <code>ccsTestIdpFieldsRenamed</code></li>
	<li><a href="idpDescription.cfm">Description</a> — toggle test description text</li>
	<li><a href="idpRefreshInterval.cfm">Refresh interval</a> — toggle <code>1,0,0,0</code> / <code>2,0,0,0</code></li>
	<li><a href="idpSamlUrl.cfm">SAML URL</a> — toggle between two Okta metadata URLs</li>
</ul>

<h3>Own SAML definition form field sync tests</h3>
<ul>
	<li><a href="idpOwnEntityId.cfm">Entity Id</a> — toggle default Okta entity id / alternate test entity id</li>
	<li><a href="idpOwnSsoUrl.cfm">SSO URL</a> — toggle default SSO URL / alternate test URL</li>
	<li><a href="idpOwnSsoBinding.cfm">SSO Binding</a> — toggle <code>redirect</code> / <code>post</code></li>
	<li><a href="idpOwnSloUrl.cfm">SLO URL</a> — toggle empty / alternate test SLO URL</li>
	<li><a href="idpOwnSloBinding.cfm">SLO Binding</a> — toggle empty / <code>redirect</code></li>
	<li><a href="idpOwnLogoutResponseUrl.cfm">Logout Response URL</a> — toggle empty / alternate test URL</li>
	<li><a href="idpOwnSignRequests.cfm">Sign Requests</a> — toggle enabled / disabled</li>
	<li><a href="idpOwnSignCertificate.cfm">Sign Certificate</a> — toggle between two Okta signing certificates</li>
</ul>

<h3>Cleanup</h3>
<ul>
	<li><a href="removeTestIdps.cfm">Remove all CCS test IDPs</a> — seeds all four import-type test IDPs, then removes them cluster-wide</li>
</ul>

<p><em>Import-type tests add dedicated CCS test Identity Providers through the Admin API. Field tests seed a URL-based IDP (<code>ccsTestIdpFields</code>) or an own-definition IDP (<code>ccsTestIdpOwnFields</code>) and update individual form settings via <code>modifyIdpMetadata</code>. Existing administrator IDPs such as <code>Idp_own</code> and <code>okta_idp</code> are not modified. Each test restores its changes in the <code>finally</code> block.</em></p>
</cfoutput>
