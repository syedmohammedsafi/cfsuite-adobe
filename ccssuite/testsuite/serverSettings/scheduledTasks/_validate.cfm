<cfscript>
cfcontent(type="application/json", reset=true);
try {
        configUtil = new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init();
        apiUtil = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init();
        fields = configUtil.getFields();
        checked = [];
        for(field in fields){
                if(apiUtil.requiresPeerInstancePropagation(field, "scheduledTasks"))
                        throw(message="Scheduler regression must rely on CCS, not direct peer writes: " & field);
                seed = configUtil.getTestState(field, true);
                target = configUtil.getTestState(field);
                for(task in deserializeJSON(seed))
                        configUtil.toTransferObject(task);
                for(task in deserializeJSON(target))
                        configUtil.toTransferObject(task);
                if(NOT configUtil.configsMatch(field, seed, seed) OR NOT configUtil.configsMatch(field, target, target))
                        throw(message="Scheduler self-comparison failed for " & field);
                if(configUtil.configsMatch(field, seed, target))
                        throw(message="Scheduler target does not change " & field);
                if(configUtil.configsMatch(field, target, "[]"))
                        throw(message="An unsynchronized peer incorrectly passes " & field);
                arrayAppend(checked, field);
        }
        new cfsuite.ccssuite.testAssets.scheduler.fixtureEventHandler();
        new cfsuite.ccssuite.testDriver();
        new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
        taskUtil = new cfsuite.ccssuite.utils.scheduledTasksTestUtil().init();
        taskUtil.assertEmptyFixturePresets({"validation-node"="[]"});
        for(invalidBaseline in ["", " ", "not-json", "{}", "[{}]"]){
                rejected = false;
                try {
                        taskUtil.assertEmptyFixturePresets({"validation-node"=invalidBaseline});
                }
                catch(CCSTest.SchedulerPresetUnavailable expectedFailure){
                        rejected = true;
                }
                catch(CCSTest.SchedulerFixtureCollision expectedFailure){
                        rejected = true;
                }
                if(NOT rejected)
                        throw(message="Unsafe scheduler preset was accepted");
        }
        writeOutput(serializeJSON({passed=true, fields=checked, configurationWrites=false}));
}
catch(any failure){
        cfheader(statusCode=500);
        writeOutput(serializeJSON({passed=false, message=failure.message, detail=failure.detail}));
}
</cfscript>