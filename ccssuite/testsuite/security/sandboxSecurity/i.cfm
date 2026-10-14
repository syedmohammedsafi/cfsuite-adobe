<!--- Security > Sandbox Security test index --->
<cfoutput>
<h2>Security &gt; Sandbox Security</h2>

<h3>Sync tests</h3>

<ul>
	<li><a href="sandboxSecurityEnabled.cfm">Enable ColdFusion Sandbox Security</a></li>
	<li><a href="addSandboxPath.cfm">Add Security Sandbox Path</a></li>
	<li><a href="copyFromSandbox.cfm">Add Security Sandbox — Copy From Existing</a> — copies permissions from the CFIDE system sandbox into a second, independent test path</li>
</ul>

<h3>Not in testsuite</h3>

<table border="1" cellpadding="6" cellspacing="0">
	<tr><th>Setting</th><th>Reason</th></tr>
	<tr><td>Sandbox directory permission matrix</td><td>Per-path permission structs (<code>contexts</code> in neo-security.xml) — editing individual permission rows is not covered</td></tr>
</table>

<p><em>Note: The add test uses a dedicated path (<code>_ccsSandboxTest</code>) under this folder. Only add sync is verified in the test output. Cleanup removes that path on all cluster nodes in the background (no delete verification tables). The <code>finally</code> block runs a final cleanup as a safety net. There is no separate delete testsuite.</em></p>

</cfoutput>