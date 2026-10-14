<cfscript>
adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
constants = new cfsuite.ccssuite.constants().init();
admin = adminUtil.createAdministrator();
adminUtil.login(constants.CF_CONFIG);
runtimeApi = createObject("component", "CFIDE.adminapi.runtime");
writeOutput("current: " & runtimeApi.getRuntimeProperty("serverCacheType") & "<br>");
try {
	runtimeApi.setServerCachingEngine("ehcache");
	writeOutput("set ehcache -> " & runtimeApi.getRuntimeProperty("serverCacheType") & "<br>");
}
catch(any e){ writeOutput("set ehcache ERROR: " & e.message & " | " & e.detail & "<br>"); }
adminUtil.logout(admin);
</cfscript>
