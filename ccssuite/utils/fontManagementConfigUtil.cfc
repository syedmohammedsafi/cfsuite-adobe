component output="false" {
        public function init(){
                return this;
        }

        private struct function getApi(){
                if(NOT structKeyExists(application, "constants"))
                        application.constants = new cfsuite.ccssuite.constants().init();
                var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
                var admin = adminUtil.createAdministrator();
                adminUtil.login(application.constants.CF_CONFIG);
                return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.runtime")};
        }

        private struct function getFixture(required string settingName){
                var fixture = {};
                switch(lCase(arguments.settingName)){
                        case "fontpath":
                                fixture = {family="CCSSuite Font File", face="CCSSuite Font File Regular", postscriptName="CCSSuiteFontFile-Regular", directory="file"};
                                break;
                        case "fontdirectory":
                                fixture = {family="CCSSuite Font Directory", face="CCSSuite Font Directory Regular", postscriptName="CCSSuiteFontDirectory-Regular", directory="directory"};
                                break;
                        default: throw(message="Unsupported Font Management test setting", type="CCSTest.ConfigError");
                }
                fixture.fontType = "TRUETYPE";
                fixture.usableIn = "PDF/FlashPaper";
                fixture.path = "/testAssets/fonts/" & fixture.directory & "/" & fixture.postscriptName & ".ttf";
                return fixture;
        }

        private string function normalizePath(required string path){
                var normalized = replace(trim(arguments.path), chr(92), "/", "all");
                var marker = "/testAssets/fonts/";
                var offset = findNoCase(marker, normalized);
                if(offset)
                        normalized = mid(normalized, offset, len(normalized));
                return lCase(normalized);
        }

        public array function getFontRows(boolean includeSystem = false){
                var runtime = getApi();
                try {
                        var fonts = runtime.api.getFonts();
                        if(NOT isStruct(fonts) OR NOT structKeyExists(fonts, "userfonts") OR NOT isStruct(fonts.userfonts))
                                throw(message="Runtime font API did not return a user-font struct", type="CCSTest.ConfigError");
                        var rows = [];
                        var fontGroups = [fonts.userfonts];
                        if(arguments.includeSystem){
                                if(NOT structKeyExists(fonts, "systemfonts") OR NOT isStruct(fonts.systemfonts))
                                        throw(message="Runtime font API did not return a system-font struct", type="CCSTest.ConfigError");
                                arrayAppend(fontGroups, fonts.systemfonts);
                        }
                        for(var fontGroup in fontGroups){
                          for(var family in fontGroup){
                                for(var face in fontGroup[family]){
                                        var info = fontGroup[family][face];
                                        for(var column in ["psname", "fonttype", "location", "description"]){
                                                if(NOT isStruct(info) OR NOT structKeyExists(info, column))
                                                        throw(message="Runtime font metadata is missing " & column, type="CCSTest.ConfigError");
                                        }
                                        arrayAppend(rows, {
                                                family=family, face=face, postscriptName=info.psname,
                                                fontType=info.fonttype, usableIn="PDF/FlashPaper", path=info.location
                                        });
                                }
                                  }
                        }
                        return rows;
                }
                finally {
                        runtime.adminUtil.logout(runtime.admin);
                }
        }

        private array function getReservedRows(required string settingName){
                var fixture = getFixture(arguments.settingName);
                var result = [];
                for(var row in getFontRows()){
                        if(compareNoCase(row.family, fixture.family) EQ 0){
                                if(normalizePath(row.path) NEQ normalizePath(fixture.path))
                                        throw(message="Reserved font family is registered from another path; no registration may be changed", type="CCSTest.FontFixtureCollision");
                                arrayAppend(result, row);
                        }
                }
                return result;
        }

        public string function getSetting(required string settingName){
                var rows = getReservedRows(arguments.settingName);
                for(var row in rows)
                        row.path = normalizePath(row.path);
                return serializeJSON(rows);
        }

        public string function getTestState(required string settingName){
                var fixture = getFixture(arguments.settingName);
                structDelete(fixture, "directory");
                fixture.path = normalizePath(fixture.path);
                return serializeJSON([fixture]);
        }

        public boolean function configsMatch(required string settingName, required any expectedValue, required any actualValue){
                getFixture(arguments.settingName);
                try {
                        var expected = deserializeJSON("" & arguments.expectedValue);
                        var actual = deserializeJSON("" & arguments.actualValue);
                        if(NOT isArray(expected) OR NOT isArray(actual) OR arrayLen(expected) GT 1 OR arrayLen(expected) NEQ arrayLen(actual))
                                return false;
                        if(NOT arrayLen(expected))
                                return true;
                        for(var column in ["family", "face", "postscriptName", "fontType", "usableIn", "path"]){
                                if(NOT structKeyExists(expected[1], column) OR NOT structKeyExists(actual[1], column))
                                        return false;
                                if(column EQ "path"){
                                        if(normalizePath(expected[1][column]) NEQ normalizePath(actual[1][column]))
                                                return false;
                                }
                                else if(compareNoCase(trim("" & expected[1][column]), trim("" & actual[1][column])) NEQ 0)
                                        return false;
                        }
                        return true;
                }
                catch(any failure){
                        return false;
                }
        }

        public boolean function fixtureExists(required string settingName){
                var fixture = getFixture(arguments.settingName);
                return fileExists(expandPath("/cfsuite/ccssuite" & fixture.path));
        }

        public string function setSetting(required string settingName, required any settingValue){
                var fixture = getFixture(arguments.settingName);
                var state = deserializeJSON("" & arguments.settingValue);
                if(NOT isArray(state) OR arrayLen(state) GT 1
                        OR (arrayLen(state) AND NOT configsMatch(arguments.settingName, getTestState(arguments.settingName), arguments.settingValue)))
                        throw(message="Only this test's reserved font fixture may be registered", type="CCSTest.ConfigError");
                var current = getReservedRows(arguments.settingName);
                if(arrayLen(current) GT 1)
                        throw(message="Reserved font fixture has multiple faces; refusing to modify it", type="CCSTest.FontFixtureCollision");
                var runtime = getApi();
                try {
                        if(arrayLen(state)){
                                if(NOT arrayLen(current)){
                                        var fontFile = expandPath("/cfsuite/ccssuite" & fixture.path);
                                        if(NOT fileExists(fontFile))
                                                throw(message="Deploy the generated font fixtures to every test node before registration", type="CCSTest.FontFixtureMissing");
                                        runtime.api.setFont(fontFile=arguments.settingName EQ "fontDirectory" ? getDirectoryFromPath(fontFile) : fontFile);
                                }
                        }
                        else {
                                for(var row in current)
                                        runtime.api.deleteFont(fontFile=row.path);
                        }
                }
                finally {
                        runtime.adminUtil.logout(runtime.admin);
                }
                return getSetting(arguments.settingName);
        }
}