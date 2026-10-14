<!--- Security > RDS test index --->

<cfoutput>
<h2>Security &gt; RDS</h2>
<h3>Sync tests</h3>

<ul>
	<li><a href="rdsEnabled.cfm">Enable RDS Service</a></li>
	<li><a href="useSingleRdsPassword.cfm">RDS Authentication — Single Password Only</a></li>
	<li><a href="useSeparateRdsUserAuth.cfm">RDS Authentication — Separate User Name and Password</a></li>
</ul>

<h3>Not in testsuite</h3>

<table border="1" cellpadding="6" cellspacing="0">
	<tr><th>Setting</th><th>Reason</th></tr>
	<tr><td>RDS authentication: no authentication</td><td><code>RdsSecurityEnabled=false</code> — excluded from automated toggle tests</td></tr>
	<tr><td>RDS single password / user passwords</td><td>Password values do not sync across nodes</td></tr>
</table>

</cfoutput>