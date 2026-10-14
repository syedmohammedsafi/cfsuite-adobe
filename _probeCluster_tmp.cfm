<cfscript>
testDriver = new cfsuite.ccssuite.testDriver().init();
ccsDriver = new cfsuite.ccssuite.ccsDriver();
application.ccsTestNodesScope = "all";
list = ccsDriver.getCCSConfigMapList();
writeOutput("raw list count: " & arrayLen(list) & "<br>");
for(n in list){
	writeOutput(serializeJSON(n) & "<br>");
}
writeOutput("<hr>ccsConfigMap:<br>");
testMgr = new cfsuite.ccssuite.testManager().init();
map = testMgr.getCCSConfigMap();
for(k in map.keyList()){
	writeOutput(k & " => " & serializeJSON(map[k]) & "<br>");
}
</cfscript>
