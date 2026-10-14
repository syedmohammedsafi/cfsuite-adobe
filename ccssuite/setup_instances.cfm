<cfsetting requestTimeout="600">

<cfscript>
    // 1. Initialize API and login
    admin = createObject("component", "CFIDE.adminapi.administrator");
    admin.login("password");
    srvInst = createObject("component", "CFIDE.adminapi.serverinstance");
    
    // 2. Scan server to detect occupied ports of other instances
    occupiedPorts = [8500];
    occupiedAjp = [8024];
    occupiedShutdown = [8019];

    // Read cfusion ports from its server.xml
    cfxml = "C:\ColdFusion2025\cfusion\runtime\conf\server.xml";
    if (fileExists(cfxml)) {
        try {
            cfxmlContent = fileRead(cfxml);
            serverMatch = reFindNoCase('<Server\s+[^>]*port="(\d+)"', cfxmlContent, 1, true);
            if (serverMatch.pos[1] GT 0) {
                occupiedShutdown = [val(mid(cfxmlContent, serverMatch.pos[2], serverMatch.len[2]))];
            }
            matches = reMatchNoCase('<Connector\s+[^>]+>', cfxmlContent);
            occupiedPorts = [];
            occupiedAjp = [];
            for (m in matches) {
                portMatch = reFindNoCase('port="(\d+)"', m, 1, true);
                if (portMatch.pos[1] GT 0) {
                    pVal = val(mid(m, portMatch.pos[2], portMatch.len[2]));
                    if (findNoCase("AJP/1.3", m)) {
                        arrayAppend(occupiedAjp, pVal);
                    } else {
                        arrayAppend(occupiedPorts, pVal);
                    }
                }
            }
        } catch(any e) {}
    }

    // Scan all other directories in C:\ColdFusion2025
    rootFolders = directoryList("C:\ColdFusion2025", false, "query");
    for (row in rootFolders) {
        if (row.type == "dir" AND NOT listFindNoCase("cfusion,jre,bundles,config,graphql,uninstall,instanceone,instancetwo,instancethree,instancefour", row.name)) {
            sxml = "C:\ColdFusion2025\" & row.name & "\runtime\conf\server.xml";
            if (fileExists(sxml)) {
                try {
                    sxmlContent = fileRead(sxml);
                    serverMatch = reFindNoCase('<Server\s+[^>]*port="(\d+)"', sxmlContent, 1, true);
                    if (serverMatch.pos[1] GT 0) {
                        arrayAppend(occupiedShutdown, val(mid(sxmlContent, serverMatch.pos[2], serverMatch.len[2])));
                    }
                    matches = reMatchNoCase('<Connector\s+[^>]+>', sxmlContent);
                    for (m in matches) {
                        portMatch = reFindNoCase('port="(\d+)"', m, 1, true);
                        if (portMatch.pos[1] GT 0) {
                            pVal = val(mid(m, portMatch.pos[2], portMatch.len[2]));
                            if (findNoCase("AJP/1.3", m)) {
                                arrayAppend(occupiedAjp, pVal);
                            } else {
                                arrayAppend(occupiedPorts, pVal);
                            }
                        }
                    }
                } catch(any e) {}
            }
        }
    }

    // 3. Define target instances and dynamically assign ports
    instances = [
        { name: "instanceone",   cluster: "_CF_DEFAULT",  environment: "development" },
        { name: "instancetwo",   cluster: "_CF_DEFAULT",  environment: "development" },
        { name: "instancethree", cluster: "testcluster", environment: "development" },
        { name: "instancefour",  cluster: "_CF_DEFAULT",  environment: "production"  }
    ];

    nextHTTP = 8501;
    nextAJP = 8012;
    nextShutdown = 8010;
    acceptedPorts = "8500"; // Keep 8500 always

    // Add all occupied HTTP ports of pre-existing instances to acceptedPorts
    for (p in occupiedPorts) {
        acceptedPorts = listAppend(acceptedPorts, p);
    }

    for (inst in instances) {
        while (arrayFind(occupiedPorts, nextHTTP) GT 0) {
            nextHTTP = nextHTTP + 1;
        }
        inst.port = nextHTTP;
        arrayAppend(occupiedPorts, nextHTTP);
        acceptedPorts = listAppend(acceptedPorts, nextHTTP);
        
        while (arrayFind(occupiedAjp, nextAJP) GT 0) {
            nextAJP = nextAJP + 1;
        }
        inst.ajpPort = nextAJP;
        arrayAppend(occupiedAjp, nextAJP);
        
        while (arrayFind(occupiedShutdown, nextShutdown) GT 0) {
            nextShutdown = nextShutdown + 1;
        }
        inst.shutdownPort = nextShutdown;
        arrayAppend(occupiedShutdown, nextShutdown);
        
        inst.redirectPort = inst.port - 100;
    }

    writeOutput("<h2>Automated ColdFusion Instance Creator</h2>");
    
    // 4. Load master nodes.properties and filter using acceptedPorts list
    masterNodesFile = "C:\ColdFusion2025\cfusion\lib\ccs\nodes.properties";
    nodesList = [];
    if (fileExists(masterNodesFile)) {
        try {
            rawList = deserializeJSON(fileRead(masterNodesFile));
            for (n in rawList) {
                if (listFind(acceptedPorts, n.port) GT 0) {
                    arrayAppend(nodesList, n);
                }
            }
        } catch(any e) {}
    }
    
    // Ensure cfusion (8500) is in nodesList
    hasCfusion = false;
    for (n in nodesList) {
        if (n.port == 8500) { hasCfusion = true; break; }
    }
    if (NOT hasCfusion) {
        arrayAppend(nodesList, {
            "server": "localhost",
            "ccssecretkey": "cf7cf320-2311-4443-b0b1-3ef169b6ce1a",
            "jeecontext": "",
            "port": 8500,
            "sslenabled": false
        });
    }

    // 4. Create and configure each instance
    for (inst in instances) {
        instDir = "C:\ColdFusion2025\" & inst.name;
        writeOutput("<b>Checking " & inst.name & "...</b><br>");
        
        // Create instance if it does not exist
        if (NOT directoryExists(instDir)) {
            writeOutput("Creating instance: " & inst.name & " (this can take 1-2 minutes)...<br>");
            try {
                srvInst.createServerInstance(inst.name);
                writeOutput("Instance " & inst.name & " created successfully!<br>");
            } catch (any e) {
                writeOutput("<font color='red'>Error creating instance " & inst.name & ": " & e.message & "</font><br>");
                continue;
            }
        } else {
            writeOutput("Instance " & inst.name & " already exists.<br>");
        }
        
        // Update server.xml ports to prevent conflicts
        serverXmlPath = instDir & "\runtime\conf\server.xml";
        if (fileExists(serverXmlPath)) {
            xmlContent = fileRead(serverXmlPath);
            xmlContent = reReplaceNoCase(xmlContent, '<Server port="\d+"', '<Server port="' & inst.shutdownPort & '"');
            xmlContent = reReplaceNoCase(xmlContent, '<Connector protocol="HTTP/1.1" port="\d+" redirectPort="\d+"', '<Connector protocol="HTTP/1.1" port="' & inst.port & '" redirectPort="' & inst.redirectPort & '"');
            xmlContent = reReplaceNoCase(xmlContent, '<Connector protocol="AJP/1.3" port="\d+" redirectPort="\d+"', '<Connector protocol="AJP/1.3" port="' & inst.ajpPort & '" redirectPort="' & inst.redirectPort & '"');
            fileWrite(serverXmlPath, xmlContent);
            writeOutput("Updated ports for " & inst.name & ": HTTP=" & inst.port & ", AJP=" & inst.ajpPort & ", Shutdown=" & inst.shutdownPort & "<br>");
        }
        
        // Ensure secret key is mapped
        secretKey = "";
        for (n in nodesList) {
            if (n.port == inst.port) { secretKey = n.ccssecretkey; break; }
        }
        if (len(secretKey) == 0) {
            secretKey = createUUID();
            arrayAppend(nodesList, {
                "server": "localhost",
                "ccssecretkey": secretKey,
                "jeecontext": "",
                "port": inst.port,
                "sslenabled": false
            });
        }
        
        // Write local ccs.properties configuration
        ccsDir = instDir & "\lib\ccs";
        if (NOT directoryExists(ccsDir)) {
            directoryCreate(ccsDir);
        }
        ccsPropContent = 
            "ccssecretkey=" & secretKey & chr(10) &
            "clustername=" & inst.cluster & chr(10) &
            "context=" & chr(10) &
            "currentversion=-1" & chr(10) &
            "enabled=true" & chr(10) &
            "environment=" & inst.environment & chr(10) &
            "excludefiles=jvm.config,neo-datasource.xml" & chr(10) &
            "hostname=localhost" & chr(10) &
            "hostport=" & inst.port & chr(10) &
            "loadenvfrom=" & inst.environment & chr(10) &
            "loadversionfrom=-1" & chr(10) &
            "port=7071" & chr(10) &
            "protocol=http" & chr(10) &
            "server=localhost";
        fileWrite(ccsDir & "\ccs.properties", ccsPropContent);
        writeOutput("Configured ccs.properties for " & inst.name & "<br>");
        
        // Copy CustomTags
        custTagsDir = instDir & "\CustomTags";
        if (NOT directoryExists(custTagsDir)) {
            directoryCreate(custTagsDir);
        }
        fileCopy("C:\ColdFusion2025\cfusion\CustomTags\qatest.cfm", custTagsDir & "\qatest.cfm");
        fileCopy("C:\ColdFusion2025\cfusion\CustomTags\expectedresults.cfm", custTagsDir & "\expectedresults.cfm");
        fileCopy("C:\ColdFusion2025\cfusion\CustomTags\qatestEnd.cfm", custTagsDir & "\qatestEnd.cfm");
        writeOutput("Copied CustomTags to " & inst.name & "<br>");
        writeOutput("<br>");
    }
    
    // 5. Update master nodes.properties
    nodesJSON = serializeJSON(nodesList);
    fileWrite(masterNodesFile, nodesJSON);
    writeOutput("Updated master nodes.properties.<br>");
    
    // 6. Copy nodes.properties to all instances
    for (inst in instances) {
        instDir = "C:\ColdFusion2025\" & inst.name;
        destNodesFile = instDir & "\lib\ccs\nodes.properties";
        fileCopy(masterNodesFile, destNodesFile);
    }
    writeOutput("Distributed nodes.properties to all instance directories.<br>");
    
    // 7. Deploy cfsuite and start services
    for (inst in instances) {
        instDir = "C:\ColdFusion2025\" & inst.name;
        srcSuite = "C:\ColdFusion2025\cfusion\wwwroot\cfsuite";
        destSuite = instDir & "\wwwroot\cfsuite";
        
        if (NOT directoryExists(destSuite)) {
            try {
                directoryCopy(srcSuite, destSuite, true);
                writeOutput("Deployed cfsuite codebase successfully to " & inst.name & "<br>");
            } catch (any e) {
                writeOutput("<font color='red'>Error deploying cfsuite to " & inst.name & ": " & e.message & "</font><br>");
            }
        }
        
        writeOutput("Starting service: " & inst.name & "...<br>");
        try {
            srvInst.startInstance(inst.name);
            writeOutput("<font color='green'>Service start request sent for " & inst.name & "</font><br>");
        } catch (any e) {
            writeOutput("<font color='red'>Error starting service for " & inst.name & ": " & e.message & "</font><br>");
        }
        writeOutput("<br>");
    }
    
    // 8. Reinitialize the application scope on all instances to load the new nodes configuration
    writeOutput("<b>Reinitializing application scope on all active nodes to sync CCS...</b><br>");
    for (p in occupiedPorts) {
        reinitURL = "http://localhost:" & p & "/cfsuite/ccssuite/testsuite/serverSettings/settings/enableHttpStatusCodes.cfm?reinit=1";
        try {
            cfhttp(url=reinitURL, method="GET", timeout=8);
            writeOutput("Successfully reinitialized node on port " & p & "<br>");
        } catch (any e) {
            writeOutput("Triggered reinit request to node on port " & p & " (node starting up)<br>");
        }
    }
    
    writeOutput("<h3>All setup tasks completed! Please allow 1-2 minutes for the instances to start up fully.</h3>");
</cfscript>
