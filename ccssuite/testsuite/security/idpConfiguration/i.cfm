<!--- Security > IDP Configuration test index --->
<cfoutput>
<h2>Security &gt; IDP Configuration</h2>

<h3>Import type sync tests</h3>
<ul>
	<li><a href="addIdpFromSamlUrl.cfm">Import from SAML URL</a> &mdash; alias <code>ccsTestIdpUrl</code></li>
	<li><a href="addIdpFromSamlDefinition.cfm">Import from SAML definition</a> &mdash; alias <code>ccsTestIdpDef</code></li>
	<li><a href="idpXmlMetadata.cfm">SAML Metadata XML</a> &mdash; alias <code>ccsTestIdpDef</code></li>
	<li><a href="addIdpFromXmlFile.cfm">Import from local XML file</a> &mdash; alias <code>ccsTestIdpXml</code></li>
	<li><a href="idpMetadataFileLocation.cfm">SAML Metadata file location</a> &mdash; alias <code>ccsTestIdpXml</code></li>
	<li><a href="addIdpOwnDefinition.cfm">Create own SAML definition</a> &mdash; alias <code>ccsTestIdpOwn</code></li>
</ul>

<h3>SAML URL form field sync tests</h3>
<ul>
	<li><a href="idpName.cfm">Name</a> &mdash; rename <code>ccsTestIdpFields</code> / <code>ccsTestIdpFieldsRenamed</code></li>
	<li><a href="idpDescription.cfm">Description</a> &mdash; toggle test description text</li>
	<li><a href="idpRefreshInterval.cfm">Refresh interval</a> &mdash; toggle <code>1,0,0,0</code> / <code>2,0,0,0</code></li>
	<li><a href="idpSamlUrl.cfm">SAML URL</a> &mdash; toggle between two Okta metadata URLs</li>
</ul>

<h3>Own SAML definition form field sync tests</h3>
<ul>
	<li><a href="idpOwnEntityId.cfm">Entity Id</a> &mdash; toggle default Okta entity id / alternate test entity id</li>
	<li><a href="idpOwnSsoUrl.cfm">SSO URL</a> &mdash; toggle default SSO URL / alternate test URL</li>
	<li><a href="idpOwnSsoBinding.cfm">SSO Binding</a> &mdash; toggle <code>redirect</code> / <code>post</code></li>
	<li><a href="idpOwnSloUrl.cfm">SLO URL</a> &mdash; toggle empty / alternate test SLO URL</li>
	<li><a href="idpOwnSloBinding.cfm">SLO Binding</a> &mdash; toggle empty / <code>redirect</code></li>
	<li><a href="idpOwnLogoutResponseUrl.cfm">Logout Response URL</a> &mdash; toggle empty / alternate test URL</li>
	<li><a href="idpOwnSignRequests.cfm">Sign Requests</a> &mdash; toggle enabled / disabled</li>
	<li><a href="idpOwnSignCertificate.cfm">Sign Certificate</a> &mdash; toggle between two Okta signing certificates</li>
</ul>

<h3>Cleanup</h3>
<ul>
	<li><a href="removeTestIdps.cfm">Remove all CCS test IDPs</a> &mdash; seeds all four import-type test IDPs, then removes them cluster-wide</li>
</ul>

<p><em>Import-type tests add dedicated CCS test Identity Providers through the Admin API. Field tests seed a URL-based IDP (<code>ccsTestIdpFields</code>) or an own-definition IDP (<code>ccsTestIdpOwnFields</code>) and update individual form settings via <code>modifyIdpMetadata</code>. Existing administrator IDPs such as <code>Idp_own</code> and <code>okta_idp</code> are not modified. Each test restores its changes in the <code>finally</code> block.</em></p>
</cfoutput>
