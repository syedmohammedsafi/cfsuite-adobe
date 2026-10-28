<cfscript>
cfcontent(type="text/plain", reset=true);
try {
        if(NOT structKeyExists(url, "setting") OR NOT structKeyExists(url, "area") OR compareNoCase(url.area, "nosql") NEQ 0)
                throw(type="CCSTest.NoSQLRequest", message="Invalid query parameters for NoSQL getter");
        writeOutput(new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init().getSetting(url.setting));
}
catch(any failure){
        cfheader(statusCode=500);
        writeOutput(failure.message & " " & failure.detail);
}
</cfscript>
