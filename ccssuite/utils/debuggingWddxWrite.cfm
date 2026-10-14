<cfparam name="neoDebugPath" default="">
<cfparam name="neoDebugCfg" default="#[]#">
<cfwddx action="cfml2wddx" input="#neoDebugCfg#" output="neoDebugWddx">
<cfset fileWrite(neoDebugPath, neoDebugWddx)>
