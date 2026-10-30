<cfset request.scheduledTaskSetting = "dsnname">
<cfset request.createSchedulerTables = true>
<cfinclude template="_clusterDatasourceForm.cfm">
<cfinclude template="_test.cfm">