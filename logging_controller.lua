---Basic Logging Controller that is able to send logs from Corona to Loggly.com
---Authored by Mike Turner, managing partner of Charmed Matter Games

---Usage:
---.log method can send any lua table to Loggly's rest endpoint (you must have a Loggly account) as
---long as the table is formatted as valid JSON (i.e. only use number, string, or table data types)

---.stackErrorHandler method can be subscribed to "unhandledError" runtime event to send crash messages
---and stack traces to Loggly, recommend subscribing .stackErrorHandler in your main.lua file
---the logging controller can be instantiated in any lua code file with "require" statement

---FOR THIS LIBRARY TO WORK PROPERLY: You must register for a free account at
---http://loggly.com, once there, you will be given a unique token, place that token
---in place of TOKEN in the Loggly REST endpoint variables
 


---Import necessary Corona libraries & let corona console know logging contoller started
print("Loggly logging controller being instantiated")
local json = require( "json" )
local network = require( "network" )

---Create logging controller container
local loggingController = {}

---Loggly REST Endpoints, replace TOKEN with your unique Loggly token---
local logglyRestEndpoint = {}
logglyRestEndpoint.Single = "http://logs-01.loggly.com/inputs/TOKEN/tag/http/"
logglyRestEndpoint.Batch = "http://logs-01.loggly.com/inputs/TOKEN/tag/bulk/"

---Capture Device Metadata & Store it to send with log message (ADVICE: Add other metadata here that is useful)---
local deviceMetaData = {}
if system.getInfo("environment") == "device" then
    deviceMetaData.gameName = system.getInfo("appName")
    deviceMetaData.gameVersion = system.getInfo("appVersionString")
    deviceMetaData.deviceOS = system.getInfo("model")
elseif system.getInfo("environment") == "simulator" then
    deviceMetaData.deviceOS = "Corona " .. system.getInfo("model") .. " simulator"
end

---Utility Functions (Only meant to be used by controller, not externally)---

--Network Listener to Handle replies from Loggly
loggingController.networkListener = function( event )
     if ( event.isError ) then
         print( "Response from loggly.com: Network error!" )
     else
         print ( "Loggly.com RESPONSE: " .. event.response, 4)
     end
 end

---Logging Functions---

--Send logging event
 loggingController.log = function(logEvent)

        --check if log event is contained in a table, if not exit function and send warning message to the console
        if not type(logEvent) == "table" then
            print("log event input is not in a lua table, event not sent, all log event input must be contained in a lua table")
            return
        end

        --Add a field "deviceMetaData" and store device meta data as shown above
        logEvent.deviceMetaData = deviceMetaData

        --Send message. First create message table (for headers, body, etc.), then within the
        --body, encode log event passed into JSON and then send message with network.request
        local message = {}
        message.body = json.encode(logEvent)
        network.request(logglyRestEndpoint.Single, "POST", loggingController.networkListener, message)

 end

-- Function for logging stack traces from application crashes, used by subscribing this function to
-- runtime event "unhandledError" via Runtime:addEventListener("unhandledError", loggingController.stackErrorHandler)
-- recommended to subscribe this event to "unhandledError" event in your main.lua file
loggingController.stackErrorHandler = function( event )
    print("stackErroHandlerCalled event.errormesage is" .. event.errorMessage)

    --Store error in a lua table
    local fatalError = {errorMessage = tostring(event.errorMessage), stackTrace = tostring(event.stackTrace) }

    --Send logging event with the function developed above
    loggingController.log(fatalError)
 end

---Return logging controller for external usage
return loggingController