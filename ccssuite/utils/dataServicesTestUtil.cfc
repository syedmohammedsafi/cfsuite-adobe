/**
* Shared helpers for Data & Services testsuite CFM pages. NoSQL Data Sources is alias-keyed
* (one datasource per "name") the same way AI Services vector stores are, so this reuses the
* same generic sync-test engine (aiServicesTestUtil.runMultiNodeLLMSyncTest) rather than
* duplicating it — that function only needs a settingName/scriptPath/apiArea, nothing AI-specific.
*/
component output="true" {

	variables.NOSQL_TEST_ALIAS = "CCSTestMongoDS";

	public function init(){
		return this;
	}

	public struct function runDatasourceSyncTest(required any testDriver, required string settingName, required string scriptPath){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var configUtil = new cfsuite.ccssuite.utils.datasourceConfigUtil().init();
		var originalFrame = {};
		var originalValues = {};
		var writesStarted = false;
		try {
			stUtil.initializeCcsNodeConfig("all");
			originalFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
			originalValues = stUtil.collectPresetValuesFromFrame(originalFrame);
			configUtil.assertEmptyFixturePresets(arguments.settingName, originalValues);
			var target = configUtil.getTestState(arguments.settingName);
			if(configUtil.isJndiSetting(arguments.settingName))
				new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().requireFixtureResources(arguments.settingName);
			if(configUtil.isMysqlSetting(arguments.settingName))
				new cfsuite.ccssuite.utils.mysqlDatasourceConfigUtil().init().requireConnectorJ();
			if(configUtil.isOdbcSocketSetting(arguments.settingName))
				new cfsuite.ccssuite.utils.odbcSocketDatasourceConfigUtil().init().requireFixtureResources(arguments.settingName);
			writesStarted = true;
						if(configUtil.isPreparedDatasourceSetting(arguments.settingName)){
				var seed = configUtil.getSeedState(arguments.settingName);
				arguments.testDriver.setAndGetSyncedValues(originalFrame, seed, arguments.settingName);
				var seededFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
				if(NOT configUtil.configsMatch(arguments.settingName, seed, stUtil.getPresetValueFromFrame(seededFrame, arguments.settingName)))
										throw(message="Reserved datasource baseline registration did not match the expected fields", type="CCSTest.FixtureSeedFailed");
			}
			var result = stUtil.runMultiNodeSettingSyncTest(
				arguments.testDriver, arguments.settingName, arguments.scriptPath, target, originalFrame, false, "all", false,
								configUtil.isPreparedDatasourceSetting(arguments.settingName) ? originalValues : {}
			);
			result.datasourceOriginalFrame = originalFrame;
			result.datasourceOriginalValues = originalValues;
			return result;
		}
		catch(any failure){
			if(writesStarted){
				application.ccsTestNodesScope = "all";
				arguments.testDriver.restoreOriginalSettingPerNode(originalFrame, originalValues, arguments.settingName);
			}
			rethrow;
		}
		finally {
			application.ccsTestNodesScope = "currentPort";
		}
	}

	public void function restoreDatasourceSyncTest(required any testDriver, required struct result, required string settingName){
		if(NOT structKeyExists(arguments.result, "datasourceOriginalFrame"))
			return;
		try {
			application.ccsTestNodesScope = "all";
			arguments.testDriver.restoreOriginalSettingPerNode(arguments.result.datasourceOriginalFrame, arguments.result.datasourceOriginalValues, arguments.settingName);
		}
		finally {
			application.ccsTestNodesScope = "currentPort";
		}
	}

	public string function getNoSQLTestAlias(){
		return variables.NOSQL_TEST_ALIAS;
	}

	public struct function initTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().initTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
	}

	public any function getPresetValueFromFrame(required struct testFrame, string settingName = ""){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().getPresetValueFromFrame(
			arguments.testFrame,
			arguments.settingName
		);
	}

	public string function getQatestResultMessage(required boolean passed){
		return new cfsuite.ccssuite.utils.aiServicesTestUtil().init().getQatestResultMessage(arguments.passed);
	}

	public void function restoreTest(required any testDriver, required struct initedTestFrame, required any originalValue, required string settingName){
		new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().restoreTest(
			arguments.testDriver,
			arguments.initedTestFrame,
			arguments.originalValue,
			arguments.settingName
		);
	}

	public struct function getDefaultNoSQLConfig(){
		return {
			"type": "mongodb",
			"host": "127.0.0.1",
			"port": 27017,
			"replicaSet": "",
			"ssl": false,
			"dnsSeedList": false,
			"authMechanism": "usernamepassword",
			"readConcern": "LOCAL",
			"readPreference": "PRIMARY",
			"j": false,
			"connectTimeout": 20000,
			"maxPoolSize": 100,
			"minPoolSize": 0,
			"maxConnectionLifeTime": 0,
			"maxConnectionIdleTime": 0,
			"maxWaitQueueTimeout": 120000,
			"maxWaitQueueSize": 500,
			"heartbeatFrequency": 10000,
			"minHeartbeatFrequency": 500
		};
	}

	private string function encodeNoSQLConfig(required struct config){
		return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().encodeConfigValue(arguments.config);
	}

	private struct function decodeNoSQLConfig(required any settingValue){
		return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().decodeConfigValue(arguments.settingValue);
	}

	private boolean function isEmptyNoSQLSettingValue(required any value){
		return structIsEmpty(decodeNoSQLConfig(arguments.value));
	}

	private void function deleteNoSQLTestAliasOnAllNodes(
		required any testDriver,
		required string alias,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		var deleteFrame = initTestFrame(arguments.testDriver, arguments.alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		restoreTest(arguments.testDriver, deleteFrame, "", arguments.alias);
	}

	public struct function runFullNoSQLDatasourceSyncTest(
		required any testDriver,
		required string scriptPath,
		struct configOverrides = {},
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);

		var alias = getNoSQLTestAlias();
		deleteNoSQLTestAliasOnAllNodes(arguments.testDriver, alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initTestFrame(arguments.testDriver, alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		var originalValue = getPresetValueFromFrame(initedTestFrame, alias);
		if(isEmptyNoSQLSettingValue(originalValue))
			originalValue = "";

		var config = getDefaultNoSQLConfig();
		structAppend(config, arguments.configOverrides, true);
		var newSetValue = encodeNoSQLConfig(config);

		return aiUtil.runMultiNodeLLMSyncTest(
			arguments.testDriver,
			alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			"",
			originalValue
		);
	}

	public void function restoreNoSQLDatasourceSyncTest(required any testDriver, required struct syncTestResult){
		var alias = getNoSQLTestAlias();
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue")){
			application.ccsTestNodesScope = "currentPort";
			return;
		}

		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/DataServices/nosqlDatasources/nosqlDatasourceConfig.cfm";
		var originalValue = arguments.syncTestResult.originalValue;

		new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().initializeCcsNodeConfig("all");
		if(isEmptyNoSQLSettingValue(originalValue)){
			deleteNoSQLTestAliasOnAllNodes(arguments.testDriver, alias, scriptPath, true);
		}
		else {
			var restoreFrame = initTestFrame(arguments.testDriver, alias, scriptPath, true);
			restoreTest(arguments.testDriver, restoreFrame, originalValue, alias);
		}
		application.ccsTestNodesScope = "currentPort";
	}

	/**
	* ColdFusion Collections mirrors the same alias-style empty-then-full-config pattern, but
	* is scoped to nodesScope="currentPort" (like chartCachePathConfigUtil.cfc) since a Solr
	* collection is a physical, per-instance index — confirmed a collection created on one
	* node is not visible on a peer instance.
	*/
	variables.COLLECTION_TEST_ALIAS = "CCSTestCollection";

	public string function getCollectionTestAlias(){
		return variables.COLLECTION_TEST_ALIAS;
	}

	public struct function getDefaultCollectionConfig(){
		return {
			"language": "English",
			"termHighlighting": true
		};
	}

	private string function encodeCollectionConfig(required struct config){
		return new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().encodeConfigValue(arguments.config);
	}

	private boolean function isEmptyCollectionSettingValue(required any value){
		return structIsEmpty(new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().decodeConfigValue(arguments.value));
	}

	private void function deleteCollectionTestAliasOnAllNodes(
		required any testDriver,
		required string alias,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		var deleteFrame = initTestFrame(arguments.testDriver, arguments.alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		restoreTest(arguments.testDriver, deleteFrame, "", arguments.alias);
	}

	public struct function runFullCollectionSyncTest(
		required any testDriver,
		required string scriptPath,
		struct configOverrides = {},
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);

		var alias = getCollectionTestAlias();
		deleteCollectionTestAliasOnAllNodes(arguments.testDriver, alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initTestFrame(arguments.testDriver, alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		var originalValue = getPresetValueFromFrame(initedTestFrame, alias);
		if(isEmptyCollectionSettingValue(originalValue))
			originalValue = "";

		var config = getDefaultCollectionConfig();
		structAppend(config, arguments.configOverrides, true);
		var newSetValue = encodeCollectionConfig(config);

		return aiUtil.runMultiNodeLLMSyncTest(
			arguments.testDriver,
			alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			true,
			"",
			originalValue
		);
	}

	public void function restoreCollectionSyncTest(required any testDriver, required struct syncTestResult){
		var alias = getCollectionTestAlias();
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue")){
			application.ccsTestNodesScope = "currentPort";
			return;
		}

		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/DataServices/coldfusionCollections/collectionTermHighlighting.cfm";

		new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().initializeCcsNodeConfig("currentPort");
		deleteCollectionTestAliasOnAllNodes(arguments.testDriver, alias, scriptPath, true);
		application.ccsTestNodesScope = "currentPort";
	}
}
