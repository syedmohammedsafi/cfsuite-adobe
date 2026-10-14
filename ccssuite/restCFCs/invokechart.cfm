<cfhttp url="http://localhost:8504/rest/ccs/chart/chartingset" method="post" result="res">
<cfhttpparam type="body" name="CacheSize" value="30" >
</cfhttp>
<cfdump var=#res#>