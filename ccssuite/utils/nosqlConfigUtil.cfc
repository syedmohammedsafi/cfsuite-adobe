component output="false" {
	public function init(){ return this; }

	public boolean function statesMatch(required any expectedValue, required any actualValue){
		try {
			var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
			return structsMatch(apiUtil.decodeState(arguments.expectedValue), apiUtil.decodeState(arguments.actualValue));
		}
		catch(any failure){ return false; }
	}

	private boolean function structsMatch(required struct expected, required struct actual){
		for(var key in arguments.expected){
			if(NOT structKeyExists(arguments.actual, key))
				return false;
			var expectedFieldValue = arguments.expected[key];
			var actualFieldValue = arguments.actual[key];
			if(isStruct(expectedFieldValue)){
				if(NOT isStruct(actualFieldValue) OR NOT structsMatch(expectedFieldValue, actualFieldValue))
					return false;
			}
			else if(NOT isSimpleValue(expectedFieldValue) OR NOT isSimpleValue(actualFieldValue))
				return false;
			else if(listFindNoCase("ssl,dnsSeedList,j", key)){
				var eBool = isBoolean(expectedFieldValue) ? (expectedFieldValue ? true : false) : (listFindNoCase("true,yes,1", "" & expectedFieldValue) GT 0);
				var aBool = isBoolean(actualFieldValue) ? (actualFieldValue ? true : false) : (listFindNoCase("true,yes,1", "" & actualFieldValue) GT 0);
				if(eBool NEQ aBool)
					return false;
			}
			else if(listFindNoCase("port,wtimeout,connectTimeout,maxPoolSize,minPoolSize,maxConnectionLifeTime,maxConnectionIdleTime,maxWaitQueueTimeout,maxWaitQueueSize,heartbeatFrequency,minHeartbeatFrequency,maxStalenessSeconds", key)){
				if(val(expectedFieldValue) NEQ val(actualFieldValue))
					return false;
			}
			else if(compareNoCase(key, "password") EQ 0){
				if((len(trim(expectedFieldValue)) EQ 0) NEQ (len(trim(actualFieldValue)) EQ 0))
					return false;
			}
			else if(compareNoCase(trim("" & expectedFieldValue), trim("" & actualFieldValue)) NEQ 0)
				return false;
		}
		return true;
	}
}
