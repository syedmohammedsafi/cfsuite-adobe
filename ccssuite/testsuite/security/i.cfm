<!--- Security settings test index --->
<cfoutput>
<h2>Security Settings Tests</h2>
<p>ColdFusion Administrator &gt; Security</p>

<h3>Administrator</h3>
<ul>
	<li><a href="administrator/i.cfm">Administrator</a> — Authentication type, concurrent login sessions</li>
</ul>

<h3>RDS</h3>
<ul>
	<li><a href="rds/i.cfm">RDS</a> — Enable RDS service, RDS authentication type</li>
</ul>

<h3>Sandbox Security</h3>
<ul>
	<li><a href="sandboxSecurity/i.cfm">Sandbox Security</a> — Enable sandbox security, add/delete sandbox paths</li>
</ul>

<h3>User Manager</h3>
<ul>
	<li><a href="userManager/i.cfm">User Manager</a> — Add user, RDS/admin access, roles, data sources, secured paths</li>
</ul>

<h3>Allowed IP Addresses</h3>
<ul>
	<li><a href="allowedIpAddresses/i.cfm">Allowed IP Addresses</a> — Add/remove an allowed admin IP</li>
</ul>

<h3>Secure Profile</h3>
<ul>
	<li><a href="secureProfile/i.cfm">Secure Profile</a> — Enable/disable the Secure Profile settings bundle</li>
</ul>

<h3>IDP Configuration</h3>
<ul>
	<li><a href="idpConfiguration/i.cfm">IDP Configuration</a> — Add IDPs from URL/SAML definition/XML/own definition, remove test IDPs</li>
</ul>

<h3>SP Configuration</h3>
<ul>
	<li><a href="spConfiguration/i.cfm">SP Configuration</a> — Add/generate Service Providers, form field sync tests (each test cleans up its test SPs)</li>
</ul>

<h3>Settings</h3>
<ul>
	<li><a href="settings/i.cfm">Settings</a> — Passkey/WebAuthn and client certificate authentication options</li>
</ul>
</cfoutput>
