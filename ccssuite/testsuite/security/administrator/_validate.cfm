<cfscript>
cfcontent(type="application/json", reset=true);
try {
    secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
    testUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
    result = {passed = true, configurationWrites = false, cases = []};
    for (settingName in ["AdminSamlIdentityProvider", "AdminSamlServiceProvider", "AdminSamlGroupName"]) {
        value = secUtil.getAdministratorSetting(settingName);
        arrayAppend(result.cases, {name = settingName & " readable", passed = isSimpleValue(value)});
        arrayAppend(result.cases, {name = settingName & " exact match", passed = secUtil.scalarValuesMatch("provider_one", "provider_one", settingName)});
        arrayAppend(result.cases, {name = settingName & " mismatch", passed = NOT secUtil.scalarValuesMatch("provider_one", "provider_two", settingName)});
        arrayAppend(result.cases, {name = settingName & " string display", passed = secUtil.formatDisplayValue(settingName, "provider_one") EQ "provider_one"});
    }
    for (settingName in ["AdminSamlIdentityProvider", "AdminSamlServiceProvider"]) {
        nextValue = secUtil.getAdministratorSamlNextValue(settingName, "provider_one", ["provider_one", "provider_two"]);
        arrayAppend(result.cases, {name = settingName & " existing alternate", passed = nextValue EQ "provider_two"});
        rejected = false;
        try {
            secUtil.getAdministratorSamlNextValue(settingName, "provider_one", ["provider_one"]);
        }
        catch (CCSTest.PrerequisiteMissing expectedException) {
            rejected = true;
        }
        arrayAppend(result.cases, {name = settingName & " missing alternate", passed = rejected});
    }
    groupValue = secUtil.getAdministratorSamlNextValue("AdminSamlGroupName", "admin");
    arrayAppend(result.cases, {name = "group alias changes", passed = compare(groupValue, "admin") NEQ 0});
    arrayAppend(result.cases, {name = "group alias toggles", passed = compare(groupValue, secUtil.getAdministratorSamlNextValue("AdminSamlGroupName", groupValue)) NEQ 0});
    validPrerequisites = {authType = "SAML", config = {idpName = "idp_one", spName = "sp_one", groupName = "admin"}, idpNames = ["idp_one"], spNames = ["sp_one"]};
    secUtil.assertAdministratorSamlPrerequisites(validPrerequisites);
    arrayAppend(result.cases, {name = "valid SAML prerequisites", passed = true});
    inactivePrerequisites = duplicate(validPrerequisites);
    inactivePrerequisites.authType = "NONE";
    inactivePrerequisites.config = {};
    preparedConfig = secUtil.buildAdministratorSamlTestConfig(inactivePrerequisites);
    arrayAppend(result.cases, {name = "prepare SAML from NONE without saved pairing", passed = preparedConfig.idpName EQ "idp_one" AND preparedConfig.spName EQ "sp_one" AND len(preparedConfig.groupName) GT 0});
    arrayAppend(result.cases, {name = "preparation preserves snapshot", passed = structIsEmpty(inactivePrerequisites.config) AND inactivePrerequisites.authType EQ "NONE"});
    arrayAppend(result.cases, {name = "NONE snapshot matches restored absent pairing", passed = secUtil.administratorSamlStatesMatch(inactivePrerequisites, duplicate(inactivePrerequisites))});
    leftoverState = duplicate(inactivePrerequisites);
    leftoverState.config = preparedConfig;
    arrayAppend(result.cases, {name = "leftover SAML pairing detected", passed = NOT secUtil.administratorSamlStatesMatch(inactivePrerequisites, leftoverState)});
    leftoverState = duplicate(inactivePrerequisites);
    leftoverState.authType = "SAML";
    arrayAppend(result.cases, {name = "leftover SAML mode detected", passed = NOT secUtil.administratorSamlStatesMatch(inactivePrerequisites, leftoverState)});
    leftoverState = duplicate(inactivePrerequisites);
    arrayAppend(leftoverState.idpNames, "ccsTestIdpDef");
    arrayAppend(result.cases, {name = "leftover temporary provider detected", passed = NOT secUtil.administratorSamlStatesMatch(inactivePrerequisites, leftoverState)});
    arrayAppend(result.cases, {name = "snapshot JSON comparison", passed = secUtil.scalarValuesMatch(serializeJSON(inactivePrerequisites), serializeJSON(inactivePrerequisites), "AdminSamlTestState")});
    arrayAppend(result.cases, {name = "incomplete preparation rejected", passed = NOT secUtil.scalarValuesMatch("prepare", serializeJSON(inactivePrerequisites), "AdminSamlTestState")});
    preparedState = duplicate(validPrerequisites);
    preparedState.idpNames = ["idp_one", "ccsTestIdpDef", "ccsTestIdpXml"];
    preparedState.spNames = ["sp_one", "ccsTestSpAdd", "ccsTestSpGen"];
    arrayAppend(result.cases, {name = "prepared state verification", passed = secUtil.scalarValuesMatch("prepare", serializeJSON(preparedState), "AdminSamlTestState")});
    reorderedState = duplicate(preparedState);
    reorderedState.idpNames = ["ccsTestIdpXml", "ccsTestIdpDef", "idp_one"];
    reorderedState.spNames = ["ccsTestSpGen", "ccsTestSpAdd", "sp_one"];
    arrayAppend(result.cases, {name = "provider order independent", passed = secUtil.administratorSamlStatesMatch(preparedState, reorderedState)});
    for (invalidType in ["inactive", "missingConfig", "missingProvider"]) {
        invalidPrerequisites = duplicate(validPrerequisites);
        if (invalidType EQ "inactive") invalidPrerequisites.authType = "NONE";
        if (invalidType EQ "missingConfig") invalidPrerequisites.config = {};
        if (invalidType EQ "missingProvider") invalidPrerequisites.idpNames = [];
        rejected = false;
        try {
            secUtil.assertAdministratorSamlPrerequisites(invalidPrerequisites);
        }
        catch (CCSTest.PrerequisiteMissing expectedException) {
            rejected = true;
        }
        arrayAppend(result.cases, {name = invalidType & " rejected", passed = rejected});
    }
    for (page in ["samlIdentityProvider.cfm", "samlServiceProvider.cfm", "samlGroupName.cfm"]) {
        source = fileRead(expandPath(page));
        arrayAppend(result.cases, {name = page & " restoration", passed = findNoCase("<cffinally>", source) GT 0 AND findNoCase("restoreSecuritySyncTest", source) GT 0});
    }
    result.samlPrerequisitesAvailable = true;
    try {
        secUtil.assertAdministratorSamlPrerequisites(secUtil.getAdministratorSamlPrerequisites());
    }
    catch (CCSTest.PrerequisiteMissing expectedException) {
        result.samlPrerequisitesAvailable = false;
    }
    for (testCase in result.cases) {
        result.passed = result.passed AND testCase.passed;
    }
    writeOutput(serializeJSON(result));
}
catch (any exception) {
    cfheader(statusCode=500);
    writeOutput(serializeJSON({passed = false, configurationWrites = false, message = exception.message}));
}
</cfscript>