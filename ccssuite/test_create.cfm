<cfset admin = createObject("component", "CFIDE.adminapi.administrator")>
<cfset admin.login("password")>

<cfset srvInst = createObject("component", "CFIDE.adminapi.serverinstance")>
<cftry>
    <cfset srvInst.createServerInstance("instanceone")>
    <cfoutput>Instance instanceone created successfully!</cfoutput>
    <cfcatch type="any">
        <cfdump var="#cfcatch#">
    </cfcatch>
</cftry>
