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
                if(structCount(arguments.expected) NEQ structCount(arguments.actual))
                        return false;
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
                                if(NOT isBoolean(expectedFieldValue) OR NOT isBoolean(actualFieldValue) OR (expectedFieldValue ? true : false) NEQ (actualFieldValue ? true : false))
                                        return false;
                        }
                        else if(listFindNoCase("port,wtimeout,connectTimeout,maxPoolSize,minPoolSize,maxConnectionLifeTime,maxConnectionIdleTime,maxWaitQueueTimeout,maxWaitQueueSize,heartbeatFrequency,minHeartbeatFrequency", key)){
                                if(NOT isNumeric(expectedFieldValue) OR NOT isNumeric(actualFieldValue) OR val(expectedFieldValue) NEQ val(actualFieldValue))
                                        return false;
                        }
                        else if(compare("" & expectedFieldValue, "" & actualFieldValue) NEQ 0)
                                return false;
                }
                return true;
        }
}