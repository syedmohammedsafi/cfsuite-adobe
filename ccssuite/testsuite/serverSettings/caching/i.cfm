<!--- Caching settings test index - Administrator Caching tab options --->
<!--- cachingJCS.cfm is excluded because it currently tests EnableNullSupport, not a caching setting. --->
<cfoutput>
<h2>Caching Settings Tests</h2>

<h3>General Caching Settings</h3>
<ul>
        <li><a href="templateCacheSize.cfm">Maximum number of cached templates (TemplateCacheSize)</a></li>
        <li><a href="trustedCache.cfm">Trusted Cache (TrustedCache)</a></li>
        <li><a href="inRequestTemplateCache.cfm">Cache Template In Request (InRequestTemplateCache)</a></li>
        <li><a href="componentCache.cfm">Component Cache (ComponentCache)</a></li>
        <li><a href="cacheWebServerPaths.cfm">Cache web server paths (CacheWebServerPaths)</a></li>
        <li><a href="saveClassFiles.cfm">Save class files (SaveClassFiles)</a></li>
        <li><a href="serverCacheType.cfm">Server wide cache engine (ServerCacheType)</a></li>
        <li><a href="enableInternalQueryCache.cfm">Use internal cache to store queries (enableInternalQueryCache)</a></li>
        <li><a href="maxcachecount.cfm">Maximum number of cached queries (maxcachecount)</a></li>
        <li><a href="selectFolder.cfm">Select folder for template cache clearing (selectFolder)</a></li>
</ul>

<h3>Memcached Settings</h3>
<ul>
        <li><a href="memcachedServers.cfm">Memcached Servers (MemcachedServer)</a></li>
        <li><a href="memcachedTimeToIdleSeconds.cfm">Max idle time (seconds) (memcachedTimeToIdleSeconds)</a></li>
        <li><a href="memcachedTimeToLiveSeconds.cfm">Max life span (seconds) (memcachedTimeToLiveSeconds)</a></li>
        <li><a href="memcachedMaxElementsInMemory.cfm">Max elements (memcachedMaxElementsInMemory)</a></li>
        <li><a href="memcachedEternal.cfm">Eternal (memcachedEternal)</a></li>
</ul>

<h3>Redis Settings</h3>
<ul>
        <li><a href="redisCacheStorageHost.cfm">Redis Server (redisCacheStorageHost)</a></li>
        <li><a href="redisCacheStoragePort.cfm">Redis Server Port (redisCacheStoragePort)</a></li>
        <li><a href="redisCacheStoragePassword.cfm">Password (redisCacheStoragePassword)</a></li>
        <li><a href="redisSessionStorageCluster.cfm">Is Cluster (redisSessionStorageCluster)</a></li>
        <li><a href="redisCacheStorageIsSSL.cfm">Is SSL Enabled (redisCacheStorageIsSSL)</a></li>
        <li><a href="redisTimeToIdleSeconds.cfm">Max idle time (seconds) (redisTimeToIdleSeconds)</a></li>
        <li><a href="redisTimeToLiveSeconds.cfm">Max life span (seconds) (redisTimeToLiveSeconds)</a></li>
        <li><a href="redisMaxElementsInMemory.cfm">Max elements (redisMaxElementsInMemory)</a></li>
        <li><a href="redisEternal.cfm">Eternal (redisEternal)</a></li>
</ul>
<h3>JCS Cache Settings</h3>
<ul>
        <li><a href="jcsdsnname.cfm">JDBC auxiliary cache datasource (jcsdsnname)</a></li>
        <li><a href="createtables.cfm">Override table if already exists (createtables)</a></li>
        <li><a href="jcsservermaxidle.cfm">Max idle time (seconds) (jcsservermaxidle)</a></li>
        <li><a href="jcsservermaxlife.cfm">Max life span (seconds) (jcsservermaxlife)</a></li>
        <li><a href="jcsservermaxobjects.cfm">Max elements (jcsservermaxobjects)</a></li>
        <li><a href="jcsservereternal.cfm">Eternal (jcsservereternal)</a></li>
</ul>
</cfoutput>
