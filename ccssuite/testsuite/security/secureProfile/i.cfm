<!--- Security > Secure Profile test index --->
<cfoutput>
<h2>Security &gt; Secure Profile</h2>

<h3>Sync tests</h3>
<ul>
	<li><a href="enableSecureProfile.cfm">Enable Secure Profile</a> — toggles the real setting via CFIDE.adminapi.security.enableSecureProfile(), then restores it</li>
</ul>

<p><em>Secure Profile applies a preset bundle of ~10 settings (RDS auth, admin userid required, internal Java
component access, session timeout, post size, flash policy server, and more) in one call — some of those live
outside <code>neo-security.xml</code>. This test flips the real flag and syncs/restores it the same way as every
other boolean setting in this suite, but restoring the OTHER bundled settings to their pre-test values is not
covered here — if this test leaves the node in a changed state, check Administrator &gt; Secure Profile by hand.</em></p>
</cfoutput>
