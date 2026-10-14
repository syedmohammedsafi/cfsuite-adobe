<!--- Security > Allowed IP Addresses test index --->
<cfoutput>
<h2>Security &gt; Allowed IP Addresses</h2>

<h3>Sync tests</h3>
<ul>
	<li><a href="addAllowedIp.cfm">Add allowed IP</a> — <code>203.0.113.50</code>, via the "IP Address" text field</li>
	<li><a href="removeAllowedIp.cfm">Remove allowed IP</a> — <code>203.0.113.50</code> pre-seeded present, then removed via the "RestrictedAdminIPList" select</li>
</ul>

<p><em>The real Admin UI page has exactly these two controls, so the testsuite mirrors them one-to-one instead of covering IPv4/IPv6/range/wildcard as separate settings. Both tests use a documentation/test-net address in <code>allowedAdminIPList</code> (Administrator access); default loopback entries (<code>127.0.0.1</code>, <code>::1</code>) are preserved. Each test restores the original state in the <code>finally</code> block.</em></p>
</cfoutput>
