<cfcomponent rest="true" restpath="ping">
	<cffunction name="ping" access="remote" returntype="string" restpath="ping" httpmethod="GET" produces="text/plain">
		<cfreturn "pong">
	</cffunction>
</cfcomponent>
