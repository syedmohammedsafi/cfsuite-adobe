<cfoutput>
        <h2>Font Management Tests</h2>
        <h3>Register New Font(s) with ColdFusion</h3>
        <ul>
                <li><a href="fontPath.cfm">New Font/Font Directory - register a font file - fontPath.cfm</a></li>
                <li><a href="fontDirectory.cfm">New Font/Font Directory - register a font directory - fontDirectory.cfm</a></li>
        </ul>
        <h3>Font data list</h3>
        <ul>
                <li><a href="fontsList.cfm">Font Family, Font Face, Postscript Name, Font Type, Usable In, Path - fontsList.cfm</a></li>
        </ul>
        <p>Registration cases require disposable CCS instances and matching fixture assets on every node. Only reserved CCSSuite font families are registered and removed. Missing CCS replication fails the test.</p>
        <p><a href="_validate.cfm">Read-only fixture and API validation - _validate.cfm</a></p>
</cfoutput>