const timeCollectionInterval : Time <- Time.create[60, 0]

const TimeAgent <- typeobject TimeAgent
    function getCurrentTime -> [ res : Time ]
end TimeAgent

const TimeAgentBuilder <- object TimeAgentBuilder
    export function create[home : Node] -> [ res : TimeAgent ]
        res <- object NewTimeAgent
            export function getCurrentTime -> [ res : Time ]
                res <- home$timeOfDay
            end getCurrentTime
        end NewTimeAgent
    end create
end TimeAgentBuilder

const TimingResult <- typeobject TimingResult
    function getTheTiming -> [res : Time]
    function getAgentTime -> [res : Time]
    function getNodeName -> [res : String]
end TimingResult

const TimingResultBuilder <- object TimingResultBuilder
    export function create[home : Node, agent : TimeAgent] -> [ res : TimingResult]
        const theNode : Node <- locate agent

        % Emulating NTP here by getting the time before and after we send the
        % request.
        const requestTime : Time <- home$timeOfDay
        const fetchedAgentTime : Time <- agent$currentTime
        const responseTime : Time <- home$timeOfDay

        const realTiming : Time <- fetchedAgentTime + ((responseTime - requestTime) / 2)
        res <- object NewTimingResult
            attached const field theTiming : Time <- realTiming
            attached const field agentTime : Time <- fetchedAgentTime
            attached const field nodeName : String <- theNode$name || " (" || theNode$LNN.asString || ")"
        end NewTimingResult
    end create
end TimingResultBuilder

const main <- object main
    operation gatherTimes[home : Node, agents : Array.of[TimeAgent]] -> [ res : Array.of[TimingResult] ]
        res <- Array.of[TimingResult].empty
        for i : Integer <- agents.lowerBound while i <= agents.upperBound by i <- i + 1
            const agent : TimeAgent <- agents.getElement[i]
            begin
                res.addUpper[TimingResultBuilder.create[home, agent]]
                unavailable
                    stdout.putstring["Agent unavailable\n"]
                end unavailable
            end
        end for
    end gatherTimes

    operation averageTime[times : Array.of[TimingResult]] -> [res : Time]
        res <- Time.create[0, 0]

        % So, initially, I attempted to calculate the average by summing up all
        % the collected times, and then dividing by the number of collected
        % times. Turns out, Time is (probably) stored as a 32-bit Integer,
        % meaning we overflow on just 2 or 3 time collections summed up. So,
        % instead, we use a more incremental average algorithm.
        for i : Integer <- times.lowerBound while i <= times.upperBound by i <- i + 1
            const t : Time <- times.getElement[i]$theTiming
            res <- res + ((t - res) / (i + 1))
        end for
    end averageTime

    operation createAgentsForNodes[activeNodes : NodeList] -> [res : Array.of[TimeAgent]]
        res <- Array.of[TimeAgent].empty
        for i : Integer <- activeNodes.lowerBound while i <= activeNodes.upperBound by i <- i + 1
            const otherNode : Node <- activeNodes.getElement[i]$theNode
            const agent : TimeAgent <- TimeAgentBuilder.create[otherNode]
            move agent to otherNode
            res.addUpper[agent]
            stdout.putstring["Installed time agent on " || otherNode$name || "\n"]
        end for
    end createAgentsForNodes

    initially
        const home : Node <- locate self
        const activeNodes <- home$activeNodes
        const agents : Array.of[TimeAgent] <- self.createAgentsForNodes[activeNodes]

        loop
            home.delay[timeCollectionInterval]

            const startTime <- home$timeOfDay
            const times <- self.gatherTimes[home, agents]
            const averageTime <- self.averageTime[times]
            const endTime <- home$timeOfDay
            const localDiffTime <- endTime - startTime
            const finalTime <- averageTime + ((endTime - startTime) / 2)
            stdout.putstring["\nThe clock is " || finalTime.asDate || " (" || finalTime.asString || " as minute:microseconds)\n"]

            for i : Integer <- times.lowerBound while i <= times.upperBound by i <- i + 1
                const timing <- times.getElement[i]
                const diff <- finalTime - timing$agentTime
                stdout.putstring
                    [  "The time agent at "
                    || timing$nodeName
                    || ", where the date and time is "
                    || timing$theTiming.asDate
                    || " ("
                    || timing$theTiming.asString
                    || " as seconds:microseconds)"
                    || ", is "
                    || diff.asString
                    || " off the calculated time\n"
                    ]
            end for
        end loop
    end initially
end main
