<cfoutput>
        <h2>Scheduled Tasks Tests</h2>
        <p>These tests modify only reserved, paused tasks dated in 2099. Run on disposable CCS instances only. Existing scheduled jobs are not edited or executed.</p>
        <p>CCS replication is required. Missing task or field synchronization is a failure, even on releases where scheduler synchronization is not implemented.</p>
        <h3>Schedule New Task</h3>
        <ul>
                <li><a href="createTask.cfm">Schedule New Task - createTask.cfm</a></li>
        </ul>

        <h3>Task identity and duration</h3>
        <ul>
                <li><a href="task.cfm">Task Name - task.cfm</a></li>
                <li><a href="group.cfm">Group - group.cfm</a></li>
                <li><a href="startdate.cfm">Start Date - startdate.cfm</a></li>
                <li><a href="enddate.cfm">End Date (optional) - enddate.cfm</a></li>
        </ul>

        <h3>Frequency</h3>
        <ul>
                <li><a href="dailyEvery.cfm">Daily every - dailyEvery.cfm</a></li>
                <li><a href="intervalHours.cfm">Hours - intervalHours.cfm</a></li>
                <li><a href="intervalMinutes.cfm">Minutes - intervalMinutes.cfm</a></li>
                <li><a href="intervalSeconds.cfm">Seconds - intervalSeconds.cfm</a></li>
                <li><a href="starttime.cfm">Start Time - starttime.cfm</a></li>
                <li><a href="endtime.cfm">End Time - endtime.cfm</a></li>
                <li><a href="repeatForever.cfm">Repeat Forever - repeatForever.cfm</a></li>
                <li><a href="repeat.cfm">Repeat / Custom Repeat Count - repeat.cfm</a></li>
                <li><a href="once.cfm">One-Time - once.cfm</a></li>
                <li><a href="startTimeOnce.cfm">One-Time at - startTimeOnce.cfm</a></li>
                <li><a href="recurring.cfm">Recurring - recurring.cfm</a></li>
                <li><a href="interval.cfm">Interval (Daily / Weekly / Monthly) - interval.cfm</a></li>
                <li><a href="startTimeDWM.cfm">Recurring at - startTimeDWM.cfm</a></li>
                <li><a href="crontime.cfm">Crontime - crontime.cfm</a></li>
                <li><a href="chained.cfm">Chained Task - chained.cfm</a></li>
        </ul>

        <h3>Request and proxy</h3>
        <ul>
                <li><a href="url.cfm">URL - url.cfm</a></li>
                <li><a href="username.cfm">User Name - username.cfm</a></li>
                <li><a href="password.cfm">Password - password.cfm</a></li>
                <li><a href="requesttimeout.cfm">Request Timeout - requesttimeout.cfm</a></li>
                <li><a href="proxyserver.cfm">Proxy Server - proxyserver.cfm</a></li>
                <li><a href="proxyport.cfm">Proxy Port - proxyport.cfm</a></li>
                <li><a href="proxyuser.cfm">Proxy User - proxyuser.cfm</a></li>
                <li><a href="proxypassword.cfm">Proxy Password - proxypassword.cfm</a></li>
        </ul>

        <h3>Output</h3>
        <ul>
                <li><a href="publish.cfm">Save output to a file - publish.cfm</a></li>
                <li><a href="file.cfm">File - file.cfm</a></li>
                <li><a href="overwrite.cfm">Overwrite - overwrite.cfm</a></li>
                <li><a href="resolveurl.cfm">Resolve internal URLs so that links remain intact - resolveurl.cfm</a></li>
        </ul>

        <h3>Additional settings</h3>
        <ul>
                <li><a href="eventhandler.cfm">Event Handler - eventhandler.cfm</a></li>
                <li><a href="exclude.cfm">Comma-separated dates or date ranges for exclusion - exclude.cfm</a></li>
                <li><a href="misfire.cfm">On Misfire - misfire.cfm</a></li>
                <li><a href="onexception.cfm">On Exception - onexception.cfm</a></li>
                <li><a href="oncomplete.cfm">On Complete - oncomplete.cfm</a></li>
                <li><a href="priority.cfm">Priority - priority.cfm</a></li>
                <li><a href="retrycount.cfm">Retry Count - retrycount.cfm</a></li>
                <li><a href="clustered.cfm">Execute in cluster setup - clustered.cfm</a></li>
        </ul>

        <h3>Cluster setup</h3>
        <ul>
                <li><a href="dsnname.cfm">Select Datasource - dsnname.cfm</a></li>
                <li><a href="createTables.cfm">Create Tables for Cluster Setup - createTables.cfm</a></li>
        </ul>
        <p><a href="_validate.cfm">Read-only fixture validation - _validate.cfm</a></p>
</cfoutput>