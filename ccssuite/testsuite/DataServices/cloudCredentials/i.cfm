<!--- Cloud Credentials test index — covers the Data & Services > Cloud Credentials admin page --->
<cfoutput>
	<h2>Cloud Credentials Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>
	<h3>Common</h3>
	<ul>
		<li><a href="cloudCredentialAlias.cfm">Credential Alias (registration)</a></li>
		<li><a href="cloudVendor.cfm">Cloud Vendor</a></li>
	</ul>

	<h3>AWS fields</h3>
	<ul>
		<li><a href="awsRegion.cfm">AWS Region</a></li>
		<li><a href="awsAccessKey.cfm">AWS Access Key</a></li>
		<li><a href="awsSecretKey.cfm">AWS Secret Key</a></li>
		<li><a href="awsSessionToken.cfm">AWS Session Token</a></li>
	</ul>

	<h3>Azure fields</h3>
	<ul>
		<li><a href="azureConnectionString.cfm">Azure Connection String</a></li>
	</ul>

	<h3>GCP fields</h3>
	<ul>
		<li><a href="gcpProjectId.cfm">Project Id</a></li>
		<li><a href="gcpCredentialJsonFilepath.cfm">Credential JSON Filepath</a></li>
	</ul>
</cfoutput>
