<cfscript>
    nkey = "localhost::8500";
    sep = "::";
    
    writeOutput("Default listToArray: ");
    writeDump(listToArray(nkey, sep));
    
    writeOutput("<br>Multi-char listToArray: ");
    writeDump(listToArray(nkey, sep, false, true));
    
    writeOutput("<br>For-in loop on string list: ");
    listStr = "a,b,c";
    try {
        for (item in listStr) {
            writeOutput(item & " ");
        }
    } catch (any e) {
        writeOutput("Error: " & e.message);
    }
</cfscript>
