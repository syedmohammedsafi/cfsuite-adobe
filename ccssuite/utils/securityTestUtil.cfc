/**
* Shared helpers for Security testsuite CFM pages.
*/
component output="false" {

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	private struct function initSecurityTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return arguments.testDriver.initTestFrameWithPreSetValues(
			arguments.settingName,
			arguments.testDriver.getGenericTestFrame(),
			arguments.scriptPath,
			"_getterSecurity.cfm",
			"_setterSecurity.cfm",
			arguments.skipUnreachableNodes
		);
	}

	public struct function runSecuritySyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		return runAdministratorSyncTest(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function runUserManagerSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var umUtil = new cfsuite.ccssuite.utils.userManagerConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		umUtil.ensureUserManagerPrerequisites();
		if(listFindNoCase("UserPassword,UserPasswordConfirm", arguments.settingName) GT 0){
			structDelete(application, "ccsTestUserPassword");
			structDelete(application, "ccsTestUserPasswordConfirm");
			stUtil.initializeCcsNodeConfig("all");
		}
		if(arguments.settingName EQ "UserExists")
			umUtil.ensureTestUserAbsent();
		else
			umUtil.ensureTestUserPresent();

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(currentNode);
		writeOutput(
			"updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #primeLabel#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(
			filterVerificationRowsForCurrentNode(syncRows),
			arguments.settingName
		);

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "usermanager"
		};
	}

	public struct function runSandboxPathAddSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		return runSandboxPathActionSyncTest(
			arguments.testDriver,
			"SandboxPath",
			arguments.scriptPath,
			"add",
			"true",
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	/**
	* "New sandbox, or pick one to copy from" -- adds a second, independent test sandbox whose permissions
	* are copied from an existing real sandbox (securityConfigUtil.getCopyFromSourceSandboxPath()), verifies
	* the copy landed on all cluster nodes, AND that its permissions genuinely match the source (presence
	* alone wouldn't catch a copy that silently fell back to some other/default permission set). Add-only,
	* same as runSandboxPathAddSyncTest -- cleanup always deletes, there's no toggle/delete variant.
	*/
	public struct function runSandboxPathCopyFromSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		final SETTING_NAME = "SandboxPathCopyFrom";
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		// getSourceSandboxPermissionsForCopy() (called inside the add step below) ensures the primary test
		// sandbox exists so there's something real to copy from. If it wasn't already present, this test --
		// not addSandboxPath.cfm -- is responsible for cleaning it back up afterward.
		var wasPrimarySandboxPresent = secUtil.isTestSandboxPathPresent();
		ensureSandboxCopyPathAbsentOnAllNodes(arguments.testDriver, SETTING_NAME, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			SETTING_NAME,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, SETTING_NAME);
		var newSetValue = "add";
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, SETTING_NAME);
		writeOutput(
			"add sandbox path (#secUtil.getTestSandboxCopyPath()#) copied from (#secUtil.getCopyFromSourceSandboxPath()#) on node: #currentNode#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			SETTING_NAME,
			newSetValue
		);

		writeSyncVerificationTable(
			filterVerificationRowsForCurrentNode(
				buildSecurityVerificationRows(syncResult.postSyncFrame, SETTING_NAME, "true", false)
			),
			SETTING_NAME
		);

		stUtil.initializeCcsNodeConfig("all");
		var afterFrame = waitForSandboxPathClusterSync(
			arguments.testDriver,
			SETTING_NAME,
			arguments.scriptPath,
			"true",
			arguments.skipUnreachableNodes
		);
		stUtil.applyExistingPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, SETTING_NAME, "true", true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);

		var permsMatch = secUtil.sandboxCopyPermissionsMatchSource();
		if(NOT permsMatch)
			writeOutput("<strong>Warning:</strong> copy-target sandbox exists but its permissions do not match the source sandbox's.<br>");

		writeOutput("<br/><br/><b>After adding the setting all instances values are:</b><br><br>");
		writeSyncVerificationTable(afterRows, SETTING_NAME);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed AND permsMatch,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = SETTING_NAME,
			wasPrimarySandboxPresent = wasPrimarySandboxPresent
		};
	}

	private void function ensureSandboxCopyPathAbsentOnAllNodes(
		required any testDriver,
		required string settingName,
		required string scriptPath
	){
		var bootstrapFrame = buildSecuritySetterTestFrame(arguments.testDriver, arguments.scriptPath, arguments.settingName);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "delete", arguments.settingName, "sandboxsecurity"))
			writeOutput("<strong>Warning:</strong> could not clear test sandbox copy path on all cluster nodes before running test.<br>");
		waitForSandboxPathClusterSync(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			"false",
			true
		);
	}

	public void function cleanupSandboxCopyPathAfterTest(required any testDriver, required string scriptPath, boolean wasPrimarySandboxPresent = true){
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		var restoreFrame = buildSecuritySetterTestFrame(arguments.testDriver, arguments.scriptPath, "SandboxPathCopyFrom");
		arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(restoreFrame, "delete", "SandboxPathCopyFrom", "sandboxsecurity");
		// getSourceSandboxPermissionsForCopy() ensures the primary test sandbox exists as a side effect of
		// the add step -- if it wasn't already there before this test ran, clean it back up too so this test
		// doesn't leave a side effect for addSandboxPath.cfm (or a human checking sandbox state) to find.
		if(NOT arguments.wasPrimarySandboxPresent)
			secUtil.ensureTestSandboxPathAbsent();
		application.ccsTestNodesScope = "currentPort";
	}

	public struct function runAllowedIpSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var ipUtil = new cfsuite.ccssuite.utils.allowedIpAddressesConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var removing = lCase(trim(arguments.settingName)) EQ lCase(ipUtil.getRemoveSettingName());
		stUtil.initializeCcsNodeConfig("all");
		if(removing){
			ipUtil.ensureTestIpPresent();
			ensureAllTestIpsPresentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		}
		else {
			ipUtil.ensureTestIpAbsent();
			ensureAllTestIpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		}

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(currentNode);
		writeOutput(
			"updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #primeLabel#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), arguments.settingName);

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "allowedipaddresses"
		};
	}

	public struct function runIdpFieldSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		idpUtil.removeFieldTestIdps();
		ensureIdpFieldTestResetOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		ensureIdpFieldTestBaseOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(currentNode);
		writeOutput(
			"updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #primeLabel#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), arguments.settingName);

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "idpconfiguration",
			isIdpFieldTest = true
		};
	}

	public struct function runIdpOwnFieldSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		idpUtil.removeOwnFieldTestIdp();
		ensureIdpOwnFieldTestResetOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		ensureIdpOwnFieldTestBaseOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(currentNode);
		writeOutput(
			"updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #primeLabel#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), arguments.settingName);

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "idpconfiguration",
			isIdpOwnFieldTest = true
		};
	}

	public struct function runIdpSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		idpUtil.ensureAllTestIdpsAbsent();
		ensureAllTestIdpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(currentNode);
		writeOutput(
			"updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #primeLabel#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), arguments.settingName);

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "idpconfiguration"
		};
	}

	public struct function runIdpRemoveAllSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		final SETTING_NAME = "IdpTestRemoveAll";
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		idpUtil.ensureAllTestIdpsAbsent();
		ensureAllTestIdpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		ensureAllTestIdpsPresentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			SETTING_NAME,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, SETTING_NAME);
		var newSetValue = "true";
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, SETTING_NAME);
		writeOutput(
			"removing all CCS test IDPs on node: #currentNode#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			SETTING_NAME,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, SETTING_NAME, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), SETTING_NAME);

		writeOutput("<br/><br/><b>After removing test IDPs all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, SETTING_NAME, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, SETTING_NAME);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = SETTING_NAME,
			apiArea = "idpconfiguration"
		};
	}

	public void function cleanupTestIdpsAfterTest(required any testDriver, required string scriptPath){
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureAllTestIdpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		idpUtil.ensureAllTestIdpsAbsent();
		application.ccsTestNodesScope = "currentPort";
	}

	private struct function buildIdpBootstrapFrame(required any testDriver, required string scriptPath){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = "IdpTestRemoveAll";
		frame[application.testConstants.TEST_FRAME.API_AREA] = "idpconfiguration";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureAllTestIdpsAbsentOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildIdpBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "true", "IdpTestRemoveAll", "idpconfiguration"))
			writeOutput("<strong>Warning:</strong> could not clear CCS test IDPs on all cluster nodes.<br>");
	}

	private void function ensureAllTestIdpsPresentOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildIdpBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "addAll", "IdpTestRemoveAll", "idpconfiguration"))
			writeOutput("<strong>Warning:</strong> could not seed CCS test IDPs on all cluster nodes.<br>");
	}

	private struct function buildIdpFieldBootstrapFrame(required any testDriver, required string scriptPath){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = "IdpFieldTestSetup";
		frame[application.testConstants.TEST_FRAME.API_AREA] = "idpconfiguration";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureIdpFieldTestBaseOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildIdpFieldBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "ensure", "IdpFieldTestSetup", "idpconfiguration"))
			writeOutput("<strong>Warning:</strong> could not seed CCS field test IDP on all cluster nodes.<br>");
	}

	private void function ensureIdpFieldTestResetOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildIdpFieldBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "reset", "IdpFieldTestSetup", "idpconfiguration");
	}

	public void function cleanupIdpFieldTestAfterTest(required any testDriver, required string scriptPath){
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureIdpFieldTestResetOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		idpUtil.removeFieldTestIdps();
		application.ccsTestNodesScope = "currentPort";
	}

	private struct function buildIdpOwnFieldBootstrapFrame(required any testDriver, required string scriptPath){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = "IdpOwnFieldTestSetup";
		frame[application.testConstants.TEST_FRAME.API_AREA] = "idpconfiguration";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureIdpOwnFieldTestBaseOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildIdpOwnFieldBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "ensure", "IdpOwnFieldTestSetup", "idpconfiguration"))
			writeOutput("<strong>Warning:</strong> could not seed CCS own field test IDP on all cluster nodes.<br>");
	}

	private void function ensureIdpOwnFieldTestResetOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildIdpOwnFieldBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "reset", "IdpOwnFieldTestSetup", "idpconfiguration");
	}

	public void function cleanupIdpOwnFieldTestAfterTest(required any testDriver, required string scriptPath){
		var idpUtil = new cfsuite.ccssuite.utils.idpConfigUtil().init();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureIdpOwnFieldTestResetOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		idpUtil.removeOwnFieldTestIdp();
		application.ccsTestNodesScope = "currentPort";
	}

	public struct function runSpFieldSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var spUtil = new cfsuite.ccssuite.utils.spConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		spUtil.removeFieldTestSps();
		ensureSpFieldTestResetOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		ensureSpFieldTestBaseOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		writeOutput("updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #currentNode#<br>");

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(arguments.testDriver, initedTestFrame, arguments.settingName, newSetValue);
		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), arguments.settingName);
		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);
		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "spconfiguration",
			isSpFieldTest = true
		};
	}

	public struct function runSpSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var spUtil = new cfsuite.ccssuite.utils.spConfigUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		spUtil.ensureAllTestSpsAbsent();
		ensureAllTestSpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		writeOutput("updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #currentNode#<br>");

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(arguments.testDriver, initedTestFrame, arguments.settingName, newSetValue);
		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), arguments.settingName);
		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);
		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = "spconfiguration"
		};
	}

	public struct function runSpRemoveAllSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		final SETTING_NAME = "SpTestRemoveAll";
		var spUtil = new cfsuite.ccssuite.utils.spConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		spUtil.ensureAllTestSpsAbsent();
		ensureAllTestSpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		ensureAllTestSpsPresentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);

		var initedTestFrame = initSecurityTestFrame(arguments.testDriver, SETTING_NAME, arguments.scriptPath, arguments.skipUnreachableNodes);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, SETTING_NAME);
		var newSetValue = "true";
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, SETTING_NAME);
		writeOutput("removing all CCS test SPs on node: #currentNode#<br>");

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(arguments.testDriver, initedTestFrame, SETTING_NAME, newSetValue);
		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, SETTING_NAME, newSetValue, false);
		writeSyncVerificationTable(filterVerificationRowsForCurrentNode(syncRows), SETTING_NAME);
		writeOutput("<br/><br/><b>After removing test SPs all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, SETTING_NAME, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, SETTING_NAME);
		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = SETTING_NAME,
			apiArea = "spconfiguration"
		};
	}

	public void function cleanupTestSpsAfterTest(required any testDriver, required string scriptPath){
		var spUtil = new cfsuite.ccssuite.utils.spConfigUtil().init();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureAllTestSpsAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		spUtil.ensureAllTestSpsAbsent();
		application.ccsTestNodesScope = "currentPort";
	}

	private struct function buildSpBootstrapFrame(required any testDriver, required string scriptPath){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = "SpTestRemoveAll";
		frame[application.testConstants.TEST_FRAME.API_AREA] = "spconfiguration";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureAllTestSpsAbsentOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildSpBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "true", "SpTestRemoveAll", "spconfiguration"))
			writeOutput("<strong>Warning:</strong> could not clear CCS test SPs on all cluster nodes.<br>");
	}

	private void function ensureAllTestSpsPresentOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildSpBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "addAll", "SpTestRemoveAll", "spconfiguration"))
			writeOutput("<strong>Warning:</strong> could not seed CCS test SPs on all cluster nodes.<br>");
	}

	private struct function buildSpFieldBootstrapFrame(required any testDriver, required string scriptPath){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = "SpFieldTestSetup";
		frame[application.testConstants.TEST_FRAME.API_AREA] = "spconfiguration";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureSpFieldTestBaseOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildSpFieldBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "ensure", "SpFieldTestSetup", "spconfiguration"))
			writeOutput("<strong>Warning:</strong> could not seed CCS field test SP on all cluster nodes.<br>");
	}

	private void function ensureSpFieldTestResetOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildSpFieldBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "reset", "SpFieldTestSetup", "spconfiguration");
	}

	public void function cleanupSpFieldTestAfterTest(required any testDriver, required string scriptPath){
		var spUtil = new cfsuite.ccssuite.utils.spConfigUtil().init();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureSpFieldTestResetOnAllClusterNodes(arguments.testDriver, arguments.scriptPath);
		spUtil.removeFieldTestSps();
		application.ccsTestNodesScope = "currentPort";
	}

	private void function ensureSpSettingAbsentOnAllClusterNodes(required any testDriver, required string scriptPath, required string settingName){
		var frame = initSecurityTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, true);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(frame, "false", arguments.settingName, "spconfiguration"))
			writeOutput("<strong>Warning:</strong> could not remove test SP for #arguments.settingName# on all cluster nodes.<br>");
	}

	public void function cleanupSpSyncTestAfterTest(required any testDriver, required string scriptPath, required string settingName){
		var spUtil = new cfsuite.ccssuite.utils.spConfigUtil().init();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureSpSettingAbsentOnAllClusterNodes(arguments.testDriver, arguments.scriptPath, arguments.settingName);
		spUtil.cleanupTestSpForSetting(arguments.settingName);
		application.ccsTestNodesScope = "currentPort";
	}

	public void function cleanupSpConfigurationAfterTest(required any testDriver, required struct syncTestResult){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/security/spConfiguration/addSp.cfm";
		var settingName = structKeyExists(arguments.syncTestResult, "settingName")
			? arguments.syncTestResult.settingName
			: "";
		stUtil.initializeCcsNodeConfig("all");
		if(structKeyExists(arguments.syncTestResult, "isSpFieldTest") AND arguments.syncTestResult.isSpFieldTest){
			writeOutput("removing CCS field test SP on all cluster nodes<br>");
			cleanupSpFieldTestAfterTest(arguments.testDriver, scriptPath);
			return;
		}
		if(listFindNoCase("SpAdd,SpGenerate", settingName)){
			writeOutput("removing CCS test SP for #settingName# on all cluster nodes<br>");
			cleanupSpSyncTestAfterTest(arguments.testDriver, scriptPath, settingName);
			return;
		}
		if(len(settingName)){
			writeOutput("removing CCS field test SP on all cluster nodes<br>");
			cleanupSpFieldTestAfterTest(arguments.testDriver, scriptPath);
		}
	}

	private struct function buildAllowedIpBootstrapFrame(required any testDriver, required string scriptPath){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = "AllowedAdminIpAdd";
		frame[application.testConstants.TEST_FRAME.API_AREA] = "allowedipaddresses";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureAllTestIpsAbsentOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildAllowedIpBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "false", "AllowedAdminIpAdd", "allowedipaddresses"))
			writeOutput("<strong>Warning:</strong> could not clear CCS test allowed admin IP on all cluster nodes.<br>");
	}

	private void function ensureAllTestIpsPresentOnAllClusterNodes(required any testDriver, required string scriptPath){
		var bootstrapFrame = buildAllowedIpBootstrapFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "true", "AllowedAdminIpAdd", "allowedipaddresses"))
			writeOutput("<strong>Warning:</strong> could not seed CCS test allowed admin IP on all cluster nodes.<br>");
	}

	private struct function runSandboxPathActionSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required string action,
		required string expectedValue,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		ensureTestSandboxPathAbsentOnAllNodes(arguments.testDriver, arguments.settingName, arguments.scriptPath);
		if(arguments.action EQ "delete"){
			secUtil.ensureTestSandboxPathPresent();
			waitForSandboxPathClusterSync(
				arguments.testDriver,
				arguments.settingName,
				arguments.scriptPath,
				"true",
				arguments.skipUnreachableNodes
			);
		}

		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = arguments.action;
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		writeOutput(
			"#arguments.action# sandbox path (#secUtil.getTestSandboxPath()#) on node: #currentNode#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);
		var syncPostFrame = duplicate(syncResult.postSyncFrame);

		writeSyncVerificationTable(
			filterVerificationRowsForCurrentNode(
				buildSecurityVerificationRows(syncPostFrame, arguments.settingName, arguments.expectedValue, false)
			),
			arguments.settingName
		);

		stUtil.initializeCcsNodeConfig("all");
		var afterFrame = waitForSandboxPathClusterSync(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.expectedValue,
			arguments.skipUnreachableNodes
		);
		stUtil.applyExistingPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, arguments.expectedValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.postSyncFrame = afterFrame;
		syncResult.passed = clusterPassed;

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			restoreSandboxPathAction = arguments.action EQ "add" ? "delete" : "add"
		};
	}

	private struct function buildSecuritySetterTestFrame(required any testDriver, required string scriptPath, string cfSettingKey = "SandboxPath"){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		var menuName = pos ? listFirst(mid(path, pos + len(marker), len(path)), "/") : "security";
		var frame = arguments.testDriver.getGenericTestFrame();
		frame[application.testConstants.TEST_FRAME.CFSETTING] = arguments.cfSettingKey;
		frame[application.testConstants.TEST_FRAME.API_AREA] = "sandboxsecurity";
		frame[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_setterSecurity.cfm";
		frame[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & menuName & "/_getterSecurity.cfm";
		return frame;
	}

	private void function ensureTestSandboxPathAbsentOnAllNodes(
		required any testDriver,
		required string settingName,
		required string scriptPath
	){
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var bootstrapFrame = buildSecuritySetterTestFrame(arguments.testDriver, arguments.scriptPath);
		if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(bootstrapFrame, "delete", "SandboxPath", "sandboxsecurity"))
			writeOutput("<strong>Warning:</strong> could not clear test sandbox path on all cluster nodes before running add test.<br>");
		secUtil.repairSystemSandboxDefinitions();
		waitForSandboxPathClusterSync(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			"false",
			true
		);
	}

	private struct function waitForSandboxPathClusterSync(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required string expectedValue,
		boolean skipUnreachableNodes = true,
		numeric maxAttempts = 8,
		numeric delayMs = 500
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var afterFrame = {};
		for(var attempt = 1; attempt LTE arguments.maxAttempts; attempt++){
			stUtil.initializeCcsNodeConfig("all");
			afterFrame = initSecurityTestFrame(
				arguments.testDriver,
				arguments.settingName,
				arguments.scriptPath,
				arguments.skipUnreachableNodes
			);
			if(allSameClusterRowsPassed(
				buildSecurityVerificationRows(afterFrame, arguments.settingName, arguments.expectedValue, true)
			))
				return afterFrame;
			if(attempt LT arguments.maxAttempts)
				sleep(arguments.delayMs);
		}
		return afterFrame;
	}

	private boolean function allSameClusterRowsPassed(required array rows, string settingName = ""){
		for(var row in arguments.rows){
			if(isSameClusterNode(row.nodeKey) AND NOT row.passed)
				return false;
		}
		return true;
	}

	private string function getCurrentServerNodeKey(){
		return CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
	}

	private array function filterVerificationRowsForCurrentNode(required array rows){
		var currentKey = getCurrentServerNodeKey();
		var filtered = [];
		for(var row in arguments.rows){
			if(row.nodeKey EQ currentKey)
				arrayAppend(filtered, row);
		}
		if(NOT arrayLen(filtered) AND arrayLen(arguments.rows))
			arrayAppend(filtered, arguments.rows[1]);
		return filtered;
	}

	public struct function runAdministratorSamlSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required struct syncTestResult
	){
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		if(NOT secUtil.isAdministratorSamlFieldSetting(arguments.settingName))
			throw(message="Unsupported Administrator SAML test setting", type="CCSTest.ConfigError");
		stUtil.initializeCcsNodeConfig("all");
		var stateFrame = initSecurityTestFrame(arguments.testDriver, "AdminSamlTestState", arguments.scriptPath, false);
		var originalStates = stUtil.collectPresetValuesFromFrame(stateFrame);
		if(structIsEmpty(originalStates))
			throw(message="No reachable Administrator SAML test nodes", type="CCSTest.PrerequisiteMissing");
		for(var nodeKey in originalStates){
			if(NOT isJSON(originalStates[nodeKey]))
				throw(message="Unable to capture Administrator authentication state on #nodeKey#", type="CCSTest.ConfigError");
		}
		arguments.syncTestResult.samlStateFrame = stateFrame;
		arguments.syncTestResult.samlOriginalStates = originalStates;
		arguments.syncTestResult.settingName = arguments.settingName;
		arguments.syncTestResult.scriptPath = arguments.scriptPath;
		arguments.syncTestResult.apiArea = "administrator";
		for(var nodeKey in originalStates){
			if(NOT arguments.testDriver.applySecuritySettingOnSingleNodeVerified(stateFrame, nodeKey, "prepare", "AdminSamlTestState", "administrator"))
				throw(message="Unable to prepare temporary Administrator SAML configuration on #nodeKey#", type="CCSTest.ConfigError");
		}
		var prerequisiteValues = stUtil.collectPresetValuesFromFrame(
			initSecurityTestFrame(arguments.testDriver, "AdminSamlPrerequisites", arguments.scriptPath, false)
		);
		var sharedIdps = [];
		var sharedSps = [];
		var firstNode = true;
		for(var nodeKey in prerequisiteValues){
			var prerequisites = deserializeJSON(prerequisiteValues[nodeKey]);
			secUtil.assertAdministratorSamlPrerequisites(prerequisites);
			if(firstNode){
				sharedIdps = duplicate(prerequisites.idpNames);
				sharedSps = duplicate(prerequisites.spNames);
				firstNode = false;
			}
			else {
				sharedIdps = sharedIdps.filter(function(alias){ return arrayFindNoCase(prerequisites.idpNames, alias) GT 0; });
				sharedSps = sharedSps.filter(function(alias){ return arrayFindNoCase(prerequisites.spNames, alias) GT 0; });
			}
		}
		if(firstNode)
			throw(message="No reachable Administrator SAML test nodes", type="CCSTest.PrerequisiteMissing");
		var frame = initSecurityTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
		var currentValue = stUtil.getPresetValueFromFrame(frame, arguments.settingName);
		var newValue = secUtil.getAdministratorSamlNextValue(arguments.settingName, currentValue,
			arguments.settingName EQ "AdminSamlIdentityProvider" ? sharedIdps : sharedSps);
		arguments.syncTestResult.initedTestFrame = frame;
		arguments.syncTestResult.originalValue = currentValue;
		arguments.syncTestResult.existingValues = stUtil.collectPresetValuesFromFrame(frame);
		arguments.syncTestResult.settingName = arguments.settingName;
		arguments.syncTestResult.scriptPath = arguments.scriptPath;
		arguments.syncTestResult.apiArea = "administrator";
		writeOutput("updating #arguments.settingName# to: #encodeForHTML(newValue)#<br>");
		var syncResult = stUtil.runSyncTest(arguments.testDriver, frame, arguments.settingName, newValue);
		var rows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newValue, true);
		writeSyncVerificationTable(rows, arguments.settingName);
		arguments.syncTestResult.passed = allSameClusterRowsPassed(rows);
		arguments.syncTestResult.syncResult = syncResult;
		return arguments.syncTestResult;
	}

	public struct function runAdministratorSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		return runSettingsSyncTest(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			"administrator",
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function runSecureProfileSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		return runSettingsSyncTest(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			"secureprofile",
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function runSettingsSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		string apiArea = "settings",
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		structDelete(application, "ccsTestNodesScope");
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		if(secUtil.isLdapConfigFieldSetting(arguments.settingName)){
			try {
				secUtil.initializeLdapTestConfiguration(true);
			} catch(any ex){}
		}
		var initedTestFrame = initSecurityTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = secUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(currentNode);
		writeOutput(
			"updating #arguments.settingName# to: #secUtil.formatDisplayValue(arguments.settingName, newSetValue)# on node: #primeLabel#<br>"
		);

		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		var syncRows = buildSecurityVerificationRows(syncResult.postSyncFrame, arguments.settingName, newSetValue, false);
		writeSyncVerificationTable(
			filterVerificationRowsForCurrentNode(syncRows),
			arguments.settingName
		);

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterFrame = duplicate(syncResult.postSyncFrame);
		applyOriginalPresetValuesToFrame(afterFrame, existingValues);
		var afterRows = buildSecurityVerificationRows(afterFrame, arguments.settingName, newSetValue, true);
		var clusterPassed = allSameClusterRowsPassed(afterRows, arguments.settingName);
		syncResult.passed = clusterPassed;
		writeSyncVerificationTable(afterRows, arguments.settingName);

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = clusterPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName,
			apiArea = arguments.apiArea
		};
	}

	public void function cleanupTestSandboxPathAfterAddTest(required any testDriver, required string scriptPath){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		var restoreFrame = buildSecuritySetterTestFrame(arguments.testDriver, arguments.scriptPath);
		arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(restoreFrame, "delete", "SandboxPath", "sandboxsecurity");
		secUtil.repairSystemSandboxDefinitions();
		application.ccsTestNodesScope = "currentPort";
	}

	public void function restoreSecuritySyncTest(required any testDriver, required struct syncTestResult){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var umUtil = new cfsuite.ccssuite.utils.userManagerConfigUtil().init();
		var apiArea = structKeyExists(arguments.syncTestResult, "apiArea")
			? arguments.syncTestResult.apiArea
			: "administrator";
		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "";
		var settingName = structKeyExists(arguments.syncTestResult, "settingName")
			? arguments.syncTestResult.settingName
			: "";
		if(apiArea NEQ "spconfiguration" AND (findNoCase("/spconfiguration/", scriptPath) OR left(settingName, 2) EQ "Sp"))
			apiArea = "spconfiguration";
		if(apiArea EQ "spconfiguration"){
			cleanupSpConfigurationAfterTest(arguments.testDriver, arguments.syncTestResult);
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		if(structKeyExists(arguments.syncTestResult, "samlOriginalStates")){
			stUtil.initializeCcsNodeConfig("all");
			var restored = true;
			try {
				for(var nodeKey in arguments.syncTestResult.samlOriginalStates){
					try {
						if(NOT arguments.testDriver.applySecuritySettingOnSingleNodeVerified(arguments.syncTestResult.samlStateFrame, nodeKey,
							arguments.syncTestResult.samlOriginalStates[nodeKey], "AdminSamlTestState", "administrator"))
							restored = false;
					}
					catch(any exception){ restored = false; }
				}
				if(NOT restored)
					throw(message="Administrator SAML cleanup incomplete: verify authentication mode, saved pairing, and temporary providers on the test nodes.", type="CCSTest.RestoreFailed");
			}
			finally { application.ccsTestNodesScope = "currentPort"; }
			return;
		}
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue"))
			return;
		settingName = structKeyExists(arguments.syncTestResult, "settingName")
			? arguments.syncTestResult.settingName
			: "AllowConcurrentAdminLogin";
		if(listFindNoCase("AdminNewPassword,AdminNewPasswordConfirm,AdminOldPassword", settingName) GT 0){
			var orig = structKeyExists(arguments.syncTestResult, "originalValue") ? arguments.syncTestResult.originalValue : "(empty)";
			writeOutput("restoring #settingName# to original value: #orig#<br>");
			new cfsuite.ccssuite.utils.securityConfigUtil().init().setAdministratorSetting(settingName, orig);
			structDelete(application, "ccsTestAdminPassword");
			writeOutput("rollback/restore of #settingName# to [#orig#] completed.<br>");
			return;
		}
		if(settingName EQ "Seed"){
			structDelete(application, "ccsTestSeed");
			var orig = structKeyExists(arguments.syncTestResult, "originalValue") ? arguments.syncTestResult.originalValue : "";
			if(len(orig)){
				writeOutput("restoring Seed to original value: #orig#<br>");
				new cfsuite.ccssuite.utils.securityConfigUtil().init().restoreActualServerSeed(orig);
				writeOutput("rollback/restore of Seed to [#orig#] completed.<br>");
			}
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		if(listFindNoCase("RdsNewPassword,RdsOldPassword,RdsNewPasswordConfirm", settingName) GT 0){
			var orig = structKeyExists(arguments.syncTestResult, "originalValue") ? arguments.syncTestResult.originalValue : "(empty)";
			writeOutput("restoring #settingName# to original value: #orig#<br>");
			new cfsuite.ccssuite.utils.securityConfigUtil().init().setRdsSetting(settingName, orig);
			structDelete(application, "ccsTestRdsPassword");
			writeOutput("rollback/restore of #settingName# to [#orig#] completed.<br>");
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		if(listFindNoCase("UserPassword,UserPasswordConfirm", settingName) GT 0){
			var orig = structKeyExists(arguments.syncTestResult, "originalValue") ? arguments.syncTestResult.originalValue : "(empty)";
			writeOutput("restoring #settingName# to original value: #orig#<br>");
			new cfsuite.ccssuite.utils.userManagerConfigUtil().init().setUserManagerSetting(settingName, orig);
			structDelete(application, "ccsTestUserPassword");
			structDelete(application, "ccsTestUserPasswordConfirm");
			writeOutput("rollback/restore of #settingName# to [#orig#] completed.<br>");
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/security/administrator/allowConcurrentAdminLogin.cfm";
		stUtil.initializeCcsNodeConfig("all");
		if(apiArea EQ "usermanager"){
			writeOutput("restoring #settingName# to original value: #secUtil.formatDisplayValue(settingName, arguments.syncTestResult.originalValue)#<br>");
			var restoreFrame = structKeyExists(arguments.syncTestResult, "initedTestFrame")
				? duplicate(arguments.syncTestResult.initedTestFrame)
				: initSecurityTestFrame(arguments.testDriver, settingName, scriptPath, true);
			stUtil.restoreTest(arguments.testDriver, restoreFrame, arguments.syncTestResult.originalValue, settingName);
			if(settingName EQ "UserExists" AND umUtil.formatBooleanSettingValue(arguments.syncTestResult.originalValue) EQ "false")
				umUtil.ensureTestUserAbsent();
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		if(apiArea EQ "allowedipaddresses"){
			writeOutput("restoring #settingName# to original value: #secUtil.formatDisplayValue(settingName, arguments.syncTestResult.originalValue)#<br>");
			var ipRestoreFrame = structKeyExists(arguments.syncTestResult, "initedTestFrame")
				? duplicate(arguments.syncTestResult.initedTestFrame)
				: initSecurityTestFrame(arguments.testDriver, settingName, scriptPath, true);
			stUtil.restoreTest(arguments.testDriver, ipRestoreFrame, arguments.syncTestResult.originalValue, settingName);
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		if(apiArea EQ "idpconfiguration"){
			if(settingName EQ "IdpTestRemoveAll")
				cleanupTestIdpsAfterTest(arguments.testDriver, scriptPath);
			else if(structKeyExists(arguments.syncTestResult, "isIdpOwnFieldTest") AND arguments.syncTestResult.isIdpOwnFieldTest){
				writeOutput("cleaning up CCS own SAML definition field test IDP on all cluster nodes<br>");
				cleanupIdpOwnFieldTestAfterTest(arguments.testDriver, scriptPath);
			}
			else if(structKeyExists(arguments.syncTestResult, "isIdpFieldTest") AND arguments.syncTestResult.isIdpFieldTest){
				writeOutput("cleaning up CCS field test IDP on all cluster nodes<br>");
				cleanupIdpFieldTestAfterTest(arguments.testDriver, scriptPath);
			}
			else {
				writeOutput("restoring #settingName# to original value: #secUtil.formatDisplayValue(settingName, arguments.syncTestResult.originalValue)#<br>");
				var idpRestoreFrame = structKeyExists(arguments.syncTestResult, "initedTestFrame")
					? duplicate(arguments.syncTestResult.initedTestFrame)
					: initSecurityTestFrame(arguments.testDriver, settingName, scriptPath, true);
				stUtil.restoreTest(arguments.testDriver, idpRestoreFrame, arguments.syncTestResult.originalValue, settingName);
			}
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		if(settingName EQ "SandboxPath"){
			var orig = lCase(trim("" & arguments.syncTestResult.originalValue));
			var restoreAction = structKeyExists(arguments.syncTestResult, "restoreSandboxPathAction")
				? lCase(trim("" & arguments.syncTestResult.restoreSandboxPathAction))
				: (listFindNoCase("true,yes,1", orig) ? "add" : "delete");
			var restoreFrame = buildSecuritySetterTestFrame(arguments.testDriver, scriptPath);
			var expectedRestore = restoreAction EQ "add" ? "true" : "false";
			if(restoreAction EQ "delete")
				writeOutput("restoring #settingName#: deleting test sandbox path on all cluster nodes<br>");
			else
				writeOutput("restoring #settingName# to original value: #arguments.syncTestResult.originalValue#<br>");
			if(NOT arguments.testDriver.applySecuritySettingOnAllPrimeNodesVerified(restoreFrame, restoreAction, "SandboxPath", "sandboxsecurity"))
				writeOutput("<strong>Warning:</strong> restore of #settingName# may be incomplete on all cluster nodes.<br>");
			waitForSandboxPathClusterSync(
				arguments.testDriver,
				settingName,
				scriptPath,
				expectedRestore,
				true
			);
			application.ccsTestNodesScope = "currentPort";
			return;
		}
		var restoreFrame = structKeyExists(arguments.syncTestResult, "initedTestFrame")
			? duplicate(arguments.syncTestResult.initedTestFrame)
			: initSecurityTestFrame(arguments.testDriver, settingName, scriptPath, true);
		stUtil.restoreTest(arguments.testDriver, restoreFrame, arguments.syncTestResult.originalValue, settingName);
		application.ccsTestNodesScope = "currentPort";
	}

	public string function getQatestResultMessage(required boolean passed){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().getQatestResultMessage(arguments.passed);
	}

	private void function applyOriginalPresetValuesToFrame(required struct testFrame, required struct existingValues){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];
		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.testFrame, setType))
				continue;
			for(var nodeKey in arguments.testFrame[setType].keyList()){
				if(structKeyExists(arguments.existingValues, nodeKey))
					arguments.testFrame[setType][nodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE] = arguments.existingValues[nodeKey];
			}
		}
	}

	public array function buildSecurityVerificationRows(
		required struct postSyncFrame,
		required string settingName,
		required any newSetValue,
		boolean showEmptyNodes = false
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var rows = [];
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.postSyncFrame, setType))
				continue;
			for(var nodeKey in arguments.postSyncFrame[setType].keyList()){
				var actual = arguments.postSyncFrame[setType][nodeKey];
				var preVal = structKeyExists(actual, application.testConstants.TEST_FRAME.PRESET_VALUE)
					? actual[application.testConstants.TEST_FRAME.PRESET_VALUE] : "";
				var postVal = structKeyExists(actual, application.testConstants.TEST_FRAME.POSTSET_VALUE)
					? actual[application.testConstants.TEST_FRAME.POSTSET_VALUE] : "";
				if(NOT arguments.showEmptyNodes AND NOT len(trim("" & preVal)) AND NOT len(trim("" & postVal)))
					continue;

				var passed = securityNodeVerificationPassed(
					arguments.settingName,
					preVal,
					postVal,
					arguments.newSetValue,
					nodeKey
				);
				var cluster = "N/A";
				var env = "N/A";
				if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(nodeKey)) {
					cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
					env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
				}

				var isCrossCluster = !isSameClusterNode(nodeKey);
				if(isCrossCluster){
					postVal = preVal;
					passed = true;
				}
				var finalPassed = (passed OR isCrossCluster);
				arrayAppend(rows, {
					nodeKey = nodeKey,
					nodeLabel = stUtil.getURLFragFromNodeKey(nodeKey),
					existingValue = secUtil.formatDisplayValue(arguments.settingName, preVal),
					updatedValue = secUtil.formatDisplayValue(arguments.settingName, postVal),
					verificationStatus = finalPassed ? "Passed" : "Failed",
					passed = finalPassed,
					syncState = isCrossCluster ? "Different cluster/env" : (finalPassed ? "Synced" : "Unexpected value"),
					cluster = len(trim("" & cluster)) ? ("" & cluster) : "N/A",
					environment = len(trim("" & env)) ? ("" & env) : "N/A",
					setType = setType
				});
			}
		}
		arraySort(rows, function(a, b){
			return compare(a.nodeLabel, b.nodeLabel);
		});
		return rows;
	}

	private boolean function securityNodeVerificationPassed(
		required string settingName,
		required any presetValue,
		required any postValue,
		required any expectedValue,
		required string nodeKey
	){
		var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
		var postText = trim("" & arguments.postValue);
		if(findNoCase("set FAILED", postText))
			return false;
		// Nodes outside this node's cluster/environment are never expected to receive the change --
		// they just need to still equal their OWN original value. Check that with a plain literal
		// compare, NOT secUtil.scalarValuesMatch(): that (and several of the setting-specific matchers
		// below, e.g. idpValuesMatch/allowedIpValuesMatch for their "remove all" settings) interpret
		// their first argument as an ACTION ("true" = remove), not a target state, so feeding
		// presetValue into them as if it were expectedValue inverts the comparison instead of checking
		// "unchanged".
		if(NOT isSameClusterNode(arguments.nodeKey))
			return trim("" & arguments.presetValue) EQ postText;
		if(secUtil.isInstanceLocalSecuritySetting(arguments.settingName)){
			if(NOT isCurrentPortNode(arguments.nodeKey))
				return false;
		}
		if(listFindNoCase("AllowedAdminIpAdd,AllowedAdminIpRemove", arguments.settingName))
			return secUtil.allowedIpValuesMatch(arguments.expectedValue, arguments.postValue, arguments.settingName);
		if(listFindNoCase("IdpFromSamlUrl,IdpFromSamlDefinition,IdpFromXmlFile,IdpOwnDefinition,IdpTestRemoveAll,IdpFieldTestSetup,IdpName,IdpDescription,IdpRefreshInterval,IdpSamlUrl,IdpOwnFieldTestSetup,IdpOwnEntityId,IdpOwnSsoUrl,IdpOwnSsoBinding,IdpOwnSloUrl,IdpOwnSloBinding,IdpOwnLogoutResponseUrl,IdpOwnSignRequests,IdpOwnSignCertificate", arguments.settingName))
			return secUtil.idpValuesMatch(arguments.expectedValue, arguments.postValue, arguments.settingName);
		if(listFindNoCase("SpAdd,SpGenerate,SpTestRemoveAll,SpFieldTestSetup,SpName,SpDescription,SpIdpInitiatedSso,SpEntityId,SpAcsUrl,SpAcsBinding,SpSloUrl,SpSloBinding,SpSignRequests,SpWantAssertionsSigned,SpLogoutResponseSigned,SpSignKeystorePath,SpSignKeystorePassword,SpSignKeystoreAlias,SpRequestStore", arguments.settingName))
			return secUtil.spValuesMatch(arguments.expectedValue, arguments.postValue, arguments.settingName);
		if(listFindNoCase("ChallengeStore,ChallengeTtl,PasskeyDefaultDatasource,ClientCertAuthEnabled,ClientCertRootAdminEnabled,ClientCertCertificateSource,ClientCertSubjectHeader,ClientCertMatchCriteria", arguments.settingName))
			return secUtil.settingsValuesMatch(arguments.expectedValue, arguments.postValue, arguments.settingName);
		return secUtil.scalarValuesMatch(arguments.expectedValue, arguments.postValue, arguments.settingName);
	}

	private boolean function isCurrentPortNode(required string nodeKey){
		var parts = listToArray(arguments.nodeKey, "::", false, true);
		if(arrayLen(parts) LT 2)
			parts = listToArray(arguments.nodeKey, ":", false, true);
		if(arrayLen(parts) LT 2)
			return false;
		return val(parts[2]) EQ val(cgi.server_port);
	}

	private string function getCurrentNodeKey(){
		var currentPort = trim("" & CGI.SERVER_PORT);
		if(structKeyExists(application, "ccsConfigMap")){
			for(var k in application.ccsConfigMap){
				if(listLast(k, "::") EQ currentPort)
					return k;
			}
		}
		return CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
	}

	private boolean function isSameClusterNode(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return true;
		var currentKey = getCurrentNodeKey();
		if(NOT application.ccsConfigMap.keyExists(currentKey) OR NOT application.ccsConfigMap.keyExists(arguments.nodeKey))
			return true;
		var currentCluster = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
		var currentEnv = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		var nodeCluster = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.CLUSTER];
		var nodeEnv = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		return currentCluster EQ nodeCluster AND currentEnv EQ nodeEnv;
	}

	private void function writeSyncVerificationTable(required array rows, required string settingName){
		new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().writeSyncVerificationTable(arguments.rows, arguments.settingName);
	}

}
