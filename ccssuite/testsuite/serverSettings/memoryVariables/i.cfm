<!--- Memory Variables settings test index — labels match CF Administrator (Server Settings > Memory Variables) --->
<cfoutput>
<h2>Memory Variables Settings Tests</h2>

<h3>General</h3>
<ul>
	<li><a href="enableJ2EESessions.cfm">Use J2EE session variables (enableJ2EESessions)</a></li>
	<li><a href="enableApplicationScope.cfm">Enable Application Variables (enableApplicationScope)</a></li>
	<li><a href="enableSessionScope.cfm">Enable Session Variables (enableSessionScope)</a></li>
</ul>

<h3>Session Storage</h3>
<ul>
	<li><a href="sessionStorage.cfm">Session Storage (sessionStorage)</a></li>
	<li><a href="reuseRedisCachingForSessionStorage.cfm">Reuse redis caching server (reuseRedisCachingForSessionStorage)</a></li>
	<li><a href="sessionStorageHost.cfm">Redis Server (sessionStorageHost)</a></li>
	<li><a href="sessionStoragePort.cfm">Redis Server Port (sessionStoragePort)</a></li>
	<li><a href="sessionStoragePassword.cfm">Password (sessionStoragePassword)</a></li>
	<li><a href="sessionStorageTimeout.cfm">Redis Server Timeout (ms) (sessionStorageTimeout)</a></li>
	<li><a href="redisSessionStorageCluster.cfm">Is Cluster (redisSessionStorageCluster)</a></li>
	<li><a href="sessionStorageSSLEnabled.cfm">Is SSL Enabled (sessionStorageSSLEnabled)</a></li>
	<li><a href="cfLoginUseSessionStorageRedis.cfm">Use redis for CFLogin (CFLoginUseSessionStorageRedis)</a></li>
</ul>

<h3>Maximum Timeout</h3>
<ul>          
	<li><a href="applicationScopeMaxTimeout.cfm">Application Variables (applicationScopeMaxTimeout)</a></li>
	<li><a href="sessionScopeMaxTimeout.cfm">Session Variables (sessionScopeMaxTimeout)</a></li>
</ul>

<h3>Default Timeout</h3>
<ul>
	<li><a href="applicationScopeTimeout.cfm">Application Variables (applicationScopeTimeout)</a></li>
	<li><a href="sessionScopeTimeout.cfm">Session Variables (sessionScopeTimeout)</a></li>
</ul>

<h3>Session Cookie Settings</h3>
<ul>
	<li><a href="sessionCookieTimeout.cfm">Cookie Timeout (SessionCookieTimeout)</a></li>
	<li><a href="httpOnlySessionCookie.cfm">HTTPOnly (HttpOnlySessionCookie)</a></li>
	<li><a href="secureSessionCookie.cfm">Secure Cookie (SecureSessionCookie)</a></li>
	<li><a href="cfInternalCookieDisableUpdate.cfm">Disable updating ColdFusion internal cookies using ColdFusion tags/functions (CFInternalCookieDisableUpdate)</a></li>
	<li><a href="sessionCookieSamesite.cfm">Cookie Samesite default value (SessionCookieSamesite)</a></li>
</ul>
</cfoutput>
