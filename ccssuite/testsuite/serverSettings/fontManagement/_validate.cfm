<cfscript>
cfcontent(type="application/json", reset=true);
adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
admin = adminUtil.createAdministrator();
try {
        if(NOT structKeyExists(application, "constants"))
                application.constants = new cfsuite.ccssuite.constants().init();
        adminUtil.login(application.constants.CF_CONFIG);
        runtime = createObject("component", "CFIDE.adminapi.runtime");
        fonts = runtime.getFonts();
        result = {configurationWrites=false, methods=[], isStruct=isStruct(fonts), isQuery=isQuery(fonts)};
        configUtil = new cfsuite.ccssuite.utils.fontManagementConfigUtil().init();
        apiUtil = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init();
        new cfsuite.ccssuite.utils.fontManagementTestUtil().init();
        new cfsuite.ccssuite.testDriver();
        new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
        result.cases = ["fontPath", "fontDirectory"];
        for(settingName in result.cases){
                target = configUtil.getTestState(settingName);
                if(NOT configUtil.fixtureExists(settingName) OR NOT configUtil.configsMatch(settingName, target, target)
                        OR configUtil.configsMatch(settingName, target, "[]") OR configUtil.configsMatch(settingName, target, ""))
                        throw(message="Font fixture or strict comparison failed for " & settingName);
                if(apiUtil.requiresPeerInstancePropagation(settingName, "fontManagement"))
                        throw(message="Font regression must rely on CCS rather than direct peer writes");
                if(NOT isJSON(apiUtil.getSetting(settingName, "fontManagement")))
                        throw(message="Font getter did not return JSON");
                for(column in ["family", "face", "postscriptName", "fontType", "usableIn", "path"]){
                        changed = deserializeJSON(target);
                        changed[1][column] = "ccssuite-invalid-column";
                        if(configUtil.configsMatch(settingName, target, serializeJSON(changed)))
                                throw(message="Font comparison ignored " & column);
                }
        }
        result.passed = true;
        for(method in getMetadata(runtime).functions){
                if(listFindNoCase("getFonts,setFont,deleteFont", method.name))
                        arrayAppend(result.methods, {name=method.name, parameters=method.parameters});
        }
        if(isStruct(fonts)){
                result.fontSets = {};
                for(fontSet in fonts){
                        group = fonts[fontSet];
                        shape = {isStruct=isStruct(group), isQuery=isQuery(group), isArray=isArray(group)};
                        if(isQuery(group))
                                shape.columns = group.columnList;
                        if(isStruct(group) AND structCount(group)){
                                fontKey = structKeyArray(group)[1];
                                shape.firstValueIsStruct = isStruct(group[fontKey]);
                                if(isStruct(group[fontKey])){
                                        shape.firstValueKeys = structKeyArray(group[fontKey]);
                                        nestedKey = shape.firstValueKeys[1];
                                        if(isStruct(group[fontKey][nestedKey]))
                                                shape.firstFontColumns = structKeyArray(group[fontKey][nestedKey]);
                                }
                        }
                        if(isArray(group) AND arrayLen(group) AND isStruct(group[1]))
                                shape.firstValueKeys = structKeyArray(group[1]);
                        result.fontSets[fontSet] = shape;
                }
        }
        writeOutput(serializeJSON(result));
}
catch(any failure){
        cfheader(statusCode=500);
        writeOutput(serializeJSON({passed=false, message=failure.message, detail=failure.detail}));
}
finally {
        adminUtil.logout(admin);
}
</cfscript>