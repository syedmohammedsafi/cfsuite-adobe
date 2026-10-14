component output="false" {
        public function init(){
                return this;
        }

        public struct function getFields(){
                return {
                        createTask="Schedule New Task",
                        task="Task Name", group="Group", startdate="Start Date", enddate="End Date",
                        dailyEvery="Daily every", intervalHours="Hours", intervalMinutes="Minutes", intervalSeconds="Seconds",
                        starttime="Custom Start Time", endtime="Custom End Time", repeatForever="Repeat Forever", repeat="Repeat Count",
                        once="One-Time", startTimeOnce="One-Time at", recurring="Recurring", interval="Daily / Weekly / Monthly",
                        startTimeDWM="Recurring at", crontime="Crontime", chained="Chained Task",
                        url="URL", username="User Name", password="Password", requesttimeout="Request Timeout",
                        proxyserver="Proxy Server", proxyport="Proxy Port", proxyuser="Proxy User", proxypassword="Proxy Password",
                        publish="Save output to a file", file="Output File", overwrite="Overwrite", resolveurl="Resolve internal URLs",
                        eventhandler="Event Handler", exclude="Excluded Dates", misfire="On Misfire", onexception="On Exception",
                        oncomplete="On Complete", priority="Priority", retrycount="Retry Count", clustered="Clustered"
                };
        }

        private struct function getApi(){
                if(NOT structKeyExists(application, "constants"))
                        application.constants = new cfsuite.ccssuite.constants().init();
                var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
                var admin = adminUtil.createAdministrator();
                adminUtil.login(application.constants.CF_CONFIG);
                return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.scheduler")};
        }

        public array function getDatasourceNames(){
                var runtime = getApi();
                try {
                        var datasources = createObject("component", "CFIDE.adminapi.datasource").getDatasources();
                        var names = structKeyArray(datasources);
                        arraySort(names, "textnocase");
                        return names;
                }
                finally {
                        runtime.adminUtil.logout(runtime.admin);
                }
        }

        public string function createClusterTables(required string datasourceName){
                var name = trim(arguments.datasourceName);
                if(NOT len(name) OR NOT arrayFindNoCase(getDatasourceNames(), name))
                        throw(message="Select a configured disposable scheduler datasource before creating tables", type="CCSTest.ConfigError");
                var runtime = getApi();
                try {
                        runtime.api.setClusterDsnName(name, true);
                        return runtime.api.getClusterDsnName();
                }
                finally {
                        runtime.adminUtil.logout(runtime.admin);
                }
        }

        private string function getProperty(required string settingName){
                if(NOT structKeyExists(getFields(), arguments.settingName))
                        throw(message="Unsupported scheduled task field", type="CCSTest.ConfigError");
                switch(lCase(arguments.settingName)){
                        case "createtask": return "task";
                        case "dailyevery": case "intervalhours": case "intervalminutes": case "intervalseconds":
                        case "once": case "recurring": return "interval";
                        case "starttimeonce": case "starttimedwm": return "starttime";
                        case "repeatforever": return "repeat";
                        default: return lCase(arguments.settingName);
                }
        }

        private string function getFixtureName(required string settingName){
                getProperty(arguments.settingName);
                return "ccssuite_scheduler_" & lCase(arguments.settingName);
        }

        private boolean function isFixture(required struct task, required string settingName){
                var name = getFixtureName(arguments.settingName);
                return structKeyExists(arguments.task, "task") AND structKeyExists(arguments.task, "group")
                        AND listFindNoCase(name & "," & name & "_renamed," & name & "_child", arguments.task.task)
                        AND listFindNoCase("CCSSUITE_SCHEDULER,CCSSUITE_SCHEDULER_ALT", arguments.task.group);
        }

        private string function sourceKey(required string property){
                switch(arguments.property){
                        case "misfire": return "onmisfire";
                        case "chained": return "chainedtask";
                        default: return arguments.property;
                }
        }

        private string function normalizeValue(required string property, required any value){
                var text = trim("" & arguments.value);
                if(listFindNoCase("password,proxypassword", arguments.property))
                        return left(text, 7) EQ "sha256:" ? text : "sha256:" & hash(text, "SHA-256");
                if(listFindNoCase("startdate,enddate", arguments.property) AND isDate(arguments.value))
                        return dateFormat(arguments.value, "yyyy-mm-dd");
                if(listFindNoCase("starttime,endtime", arguments.property) AND isDate(arguments.value))
                        return timeFormat(arguments.value, "HH:mm:ss");
                if(listFindNoCase("publish,overwrite,resolveurl,chained,clustered", arguments.property))
                        return listFindNoCase("true,yes,1", text) ? "true" : "false";
                return text;
        }

        public string function getSetting(required string settingName){
                var runtime = getApi();
                try {
                        if(arguments.settingName EQ "dsnname")
                                return runtime.api.getClusterDsnName();
                        var property = getProperty(arguments.settingName);
                        var state = [];
                        for(var task in runtime.api.getTasks()){
                                if(NOT isFixture(task, arguments.settingName))
                                        continue;
                                var details = runtime.api.findTask(task.task, task.group, "server");
                                var key = sourceKey(property);
                                if(NOT structKeyExists(details, key) AND structKeyExists(details, property))
                                        key = property;
                                var record = {task=task.task, group=task.group, status=task.status};
                                record[property] = structKeyExists(details, key) ? normalizeValue(property, details[key]) : "";
                                arrayAppend(state, record);
                        }
                        return serializeJSON(state);
                }
                finally {
                        runtime.adminUtil.logout(runtime.admin);
                }
        }

        public boolean function configsMatch(required string settingName, required any expectedValue, required any actualValue){
                if(arguments.settingName EQ "dsnname")
                        return compareNoCase(trim("" & arguments.expectedValue), trim("" & arguments.actualValue)) EQ 0;
                try {
                        var expected = deserializeJSON("" & arguments.expectedValue);
                        var actual = deserializeJSON("" & arguments.actualValue);
                        var property = getProperty(arguments.settingName);
                        if(NOT isArray(expected) OR NOT isArray(actual) OR arrayLen(expected) NEQ arrayLen(actual))
                                return false;
                        for(var expectedTask in expected){
                                var found = false;
                                for(var actualTask in actual){
                                        if(compareNoCase(expectedTask.task, actualTask.task) NEQ 0 OR compareNoCase(expectedTask.group, actualTask.group) NEQ 0)
                                                continue;
                                        var expectedField = structKeyExists(expectedTask, property) ? expectedTask[property] : "";
                                        var actualField = structKeyExists(actualTask, property) ? actualTask[property] : "";
                                        if(NOT listFindNoCase("paused,pause", actualTask.status)
                                                OR normalizeValue(property, expectedField) NEQ normalizeValue(property, actualField))
                                                return false;
                                        found = true;
                                }
                                if(NOT found)
                                        return false;
                        }
                        return true;
                }
                catch(any failure){
                        return false;
                }
        }

        public string function getTestState(required string settingName, boolean seed = false){
                if(arguments.settingName EQ "createTask" AND arguments.seed)
                        return "[]";
                var task = {
                        task=getFixtureName(arguments.settingName), group="CCSSUITE_SCHEDULER", status="Paused",
                        startdate="2099-01-01", starttime="23:55:00", interval="daily", repeat="-1",
                        url="http://127.0.0.1:1/ccssuite-scheduler-fixture", requesttimeout="5",
                        username="ccssuite-user-a", password="ccssuite-password-a",
                        proxyserver="127.0.0.1", proxyport="1", proxyuser="ccssuite-proxy-a", proxypassword="ccssuite-proxy-password-a",
                        publish=false, overwrite=true, resolveurl=false, chained=false, clustered=false,
                        misfire="ignore", onexception="ignore", priority="5", retrycount="3",
                        file="ccssuite-scheduler-output.txt", path=server.coldfusion.rootdir & "/logs/"
                };
                if(arguments.settingName EQ "repeatForever"){
                        task.interval = "60";
                        task.repeat = "2";
                }
                var child = {};
                if(arguments.settingName EQ "oncomplete"){
                        child = duplicate(task);
                        child.task &= "_child";
                        child.chained = true;
                }
                if(arguments.seed)
                        return serializeJSON(structCount(child) ? [child, task] : [task]);
                switch(lCase(arguments.settingName)){
                        case "createtask": break;
                        case "task": task.task &= "_renamed"; break;
                        case "group": task.group = "CCSSUITE_SCHEDULER_ALT"; break;
                        case "startdate": task.startdate = "2099-01-02"; break;
                        case "enddate": task.enddate = "2099-12-31"; break;
                        case "dailyevery": task.interval = "60"; break;
                        case "intervalhours": task.interval = "3600"; break;
                        case "intervalminutes": task.interval = "120"; break;
                        case "intervalseconds": task.interval = "30"; break;
                        case "starttime": case "starttimedwm": task.starttime = "23:56:00"; break;
                        case "endtime": task.interval = "60"; task.endtime = "23:59:00"; break;
                        case "repeatforever": task.interval = "60"; task.repeat = "-1"; break;
                        case "repeat": task.interval = "60"; task.repeat = "2"; break;
                        case "once": task.interval = "once"; break;
                        case "starttimeonce": task.interval = "once"; task.starttime = "23:57:00"; break;
                        case "recurring": case "interval": task.interval = "weekly"; break;
                        case "crontime": structDelete(task, "interval"); task.crontime = "0 0 12 * * ?"; break;
                        case "chained": task.chained = true; break;
                        case "url": task.url = "http://127.0.0.1:1/ccssuite-scheduler-fixture-updated"; break;
                        case "username": task.username = "ccssuite-user-b"; break;
                        case "password": task.password = "ccssuite-password-b"; break;
                        case "requesttimeout": task.requesttimeout = "7"; break;
                        case "proxyserver": task.proxyserver = "localhost"; break;
                        case "proxyport": task.proxyport = "2"; break;
                        case "proxyuser": task.proxyuser = "ccssuite-proxy-b"; break;
                        case "proxypassword": task.proxypassword = "ccssuite-proxy-password-b"; break;
                        case "publish": task.publish = true; break;
                        case "file": task.file = "ccssuite-scheduler-output-updated.txt"; break;
                        case "overwrite": task.publish = true; task.overwrite = false; break;
                        case "resolveurl": task.resolveurl = true; break;
                        case "exclude": task.exclude = "2099-01-03"; break;
                        case "misfire": task.misfire = "firenow"; break;
                        case "onexception": task.onexception = "pause"; break;
                        case "priority": task.priority = "6"; break;
                        case "retrycount": task.retrycount = "4"; break;
                        case "clustered": task.clustered = true; break;
                        case "eventhandler": task.eventhandler = "cfsuite.ccssuite.testAssets.scheduler.fixtureEventHandler"; break;
                        case "oncomplete": task.oncomplete = child.task; break;
                        default: throw(message="Unsupported scheduled task field", type="CCSTest.ConfigError");
                }
                return serializeJSON(structCount(child) ? [child, task] : [task]);
        }

        public any function toTransferObject(required struct task){
                var transfer = createObject("java", "coldfusion.osgi.to.ScheduleTagTO").init();
                var setters = {
                        task="setTask", group="setGroup", status="setStatus", startdate="setStartdate", enddate="setEnddate",
                        starttime="setStarttime", endtime="setEndtime", interval="setInterval", repeat="setRepeat",
                        url="setUrl", username="setUsername", password="setPassword", requesttimeout="setRequestTimeOut",
                        proxyserver="setProxyserver", proxyport="setProxyport", proxyuser="setProxyuser", proxypassword="setProxypassword",
                        publish="setPublish", file="setFile", path="setPath", overwrite="setOverwrite", resolveurl="setResolveUrl",
                        eventhandler="setEventhandler", exclude="setExclude", misfire="setMisfire", onexception="setOnexception",
                        oncomplete="setChianedtasks", priority="setPriority", retrycount="setRetrycount", clustered="setClustered",
                        crontime="setCrontime", chained="setChained"
                };
                transfer.setMode("server");
                transfer.setEncrypted(false);
                transfer.setProxypasswordencrypted(false);
                transfer.setShouldNotMisfire(true);
                for(var property in arguments.task){
                        if(NOT structKeyExists(setters, property))
                                throw(message="Unsupported task transfer property", type="CCSTest.ConfigError");
                        var value = arguments.task[property];
                        if(listFindNoCase("startdate,enddate", property))
                                value = parseDateTime(value & " 00:00:00");
                        else if(listFindNoCase("starttime,endtime", property))
                                value = parseDateTime("2099-01-01 " & value);
                        invoke(transfer, setters[property], [value]);
                }
                return transfer;
        }

        public string function setSetting(required string settingName, required any settingValue){
                var runtime = getApi();
                try {
                        if(arguments.settingName EQ "dsnname"){
                                if(len(trim("" & arguments.settingValue)))
                                        runtime.api.setClusterDsnName(trim("" & arguments.settingValue), false);
                                else
                                        runtime.api.disableCluster();
                                return getSetting(arguments.settingName);
                        }
                        var state = deserializeJSON("" & arguments.settingValue);
                        if(NOT isArray(state) OR arrayLen(state) GT 2)
                                throw(message="Scheduler test state must contain only reserved fixtures", type="CCSTest.ConfigError");
                        var transfers = [];
                        var identities = {};
                        for(var task in state){
                                if(NOT isFixture(task, arguments.settingName) OR NOT structKeyExists(task, "status")
                                        OR task.status NEQ "Paused" OR NOT structKeyExists(task, "startdate")
                                        OR NOT isDate(task.startdate) OR parseDateTime(task.startdate) LT parseDateTime("2099-01-01"))
                                        throw(message="Only paused, future-dated reserved scheduler fixtures may be written", type="CCSTest.ConfigError");
                                var identity = task.group & ":" & task.task;
                                if(structKeyExists(identities, identity))
                                        throw(message="Duplicate reserved scheduler fixture", type="CCSTest.ConfigError");
                                identities[identity] = true;
                                arrayAppend(transfers, toTransferObject(task));
                        }
                        for(var transfer in transfers){
                                runtime.api.updateTask(transfer);
                                cfschedule(action="pause", task=transfer.getTask(), group=transfer.getGroup(), mode="server");
                        }
                        for(var existing in runtime.api.getTasks()){
                                if(NOT isFixture(existing, arguments.settingName))
                                        continue;
                                var keep = false;
                                for(var task in state){
                                        if(compareNoCase(task.task, existing.task) EQ 0 AND compareNoCase(task.group, existing.group) EQ 0)
                                                keep = true;
                                }
                                if(NOT keep)
                                        cfschedule(action="delete", task=existing.task, group=existing.group, mode="server");
                        }
                        return getSetting(arguments.settingName);
                }
                finally {
                        runtime.adminUtil.logout(runtime.admin);
                }
        }
}