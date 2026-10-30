<!--- Security > RDS test index --->

<cfoutput>
<h2>Security &gt; RDS</h2>
<h3>Sync tests</h3>

<ul>
	<li><a href="rdsEnabled.cfm">Enable RDS Service</a></li>
	<li><a href="useSingleRdsPassword.cfm">RDS Authentication - Use a single password only (default)</a></li>
	<li><a href="useSeparateRdsUserAuth.cfm">RDS Authentication - Separate user name and password authentication (allows multiple users)</a></li>
	<li><a href="rdsNoAuth.cfm">RDS Authentication - No authentication needed (not recommended)</a></li>
	<li><a href="rdsOldPassword.cfm">Old RDS Password</a></li>
	<li><a href="rdsNewPassword.cfm">New RDS Password</a></li>
	<li><a href="rdsNewPasswordConfirm.cfm">Confirm RDS Password</a></li>
</ul>

</cfoutput>
