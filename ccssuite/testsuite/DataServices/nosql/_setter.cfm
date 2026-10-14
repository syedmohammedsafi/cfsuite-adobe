<cfscript>
cfcontent(type="text/plain", reset=true);
try {
        if(NOT structKeyExists(url, "setting") OR NOT structKeyExists(url, "setValueTo") OR
                NOT structKeyExists(url, "area") OR compareNoCase(url.area, "nosql") NEQ 0)
                throw(type="CCSTest.NoSQLRequest");
        writeOutput(new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init().setSetting(url.setting, url.setValueTo));
}
catch(any failure){
        cfheader(statusCode=500);
        writeOutput("NoSQL fixture setter failed; configuration and exception details withheld.");
}
</cfscript>