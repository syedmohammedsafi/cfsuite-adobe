<!--- Security > Settings test index --->
<cfoutput>
<h2>Security &gt; Settings</h2>

<h3>Passkey / WebAuthn</h3>
<ul>
	<li><a href="challengeStore.cfm">Challenge Store</a> — toggle <code>memory</code> / <code>ehcache</code></li>
	<li><a href="challengeTtl.cfm">Challenge TTL</a> — toggle <code>60</code> / <code>120</code> seconds</li>
	<li><a href="passkeyDefaultDatasource.cfm">Default Datasource</a> — toggle empty / <code>cfartgallery</code></li>
</ul>

<h3>Client Certificate Authentication</h3>
<ul>
	<li><a href="clientCertAuthEnabled.cfm">Enable Client Certificate Authentication</a> — toggle enabled / disabled</li>
	<li><a href="clientCertRootAdminEnabled.cfm">Enable for Root Admin</a> — toggle enabled / disabled</li>
	<li><a href="clientCertCertificateSource.cfm">Certificate Source</a> — toggle HTTP Header / CGI Variable</li>
	<li><a href="clientCertSubjectHeader.cfm">Subject Header Name</a> — toggle empty / <code>X-SSL-Client-Cert-Subject</code></li>
	<li><a href="clientCertMatchCriteria.cfm">Subject Match Criteria</a> — toggle Exact DN / Common Name (CN)</li>
</ul>

<p><em>Each test updates one Security &gt; Settings option via the Admin API and verifies cluster sync. The <code>finally</code> block restores the original value on all nodes.</em></p>
</cfoutput>
