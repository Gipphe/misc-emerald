const NodeInfo <- typeobject NodeInfo
    function getLocalTime -> [ res : Time ]
    function getNodeName -> [ res : String ]
    function getNodeLNN -> [ res : Integer ]
end NodeInfo

const NodeInfoBuilder <- object NodeInfoBuilder
    export function create[theNode : Node] -> [res : NodeInfo]
        res <- object NewNodeInfo
            attached const field localTime : Time <- theNode$timeOfDay
            attached const field nodeName : String <- theNode$name
            attached const field nodeLNN : Integer <- theNode$LNN
        end NewNodeInfo
    end create
end NodeInfoBuilder

const TimeCollector <- object TimeCollector
    attached const field times : Array.of[NodeInfo] <- Array.of[NodeInfo].empty
    process
        const home : Node <- locate self
        const activeNodes : NodeList <- home$activeNodes

        home$stdout.PutString[(activeNodes.upperbound + 1).asString || " nodes active.\n"]

        % I will blindly assume that we are also supposed to gather the
        % starting node's node info.
        home$stdout.PutString["Starting on " || home$name || "\n"]
        self$times.addUpper[NodeInfoBuilder.create[home]]

        var curr : Node
        var there : Node <- home
        for i : Integer <- activeNodes.lowerBound while i <= activeNodes.upperbound by i <- i + 1
            if activeNodes[i]$theNode$LNN != home$LNN then
                begin
                    curr <- there
                    there <- activeNodes[i]$theNode
                    move self to there
                    stdout.putstring["Moved to " || there$name || "\n"]
                    self$times.addUpper[NodeInfoBuilder.create[there]]
                    unavailable
                        curr$stdout.putstring["Unavailable: " || there$name || "\n"]
                    end unavailable
                end
            end if
        end for

        % From previous experience, we have to check whether home is still
        % available.
        begin
            move self to home
            curr <- home
            unavailable
                curr$stdout.putstring["Home is unavailable\n"]
            end unavailable
        end

        if curr == home then
            curr$stdout.PutString["Back home\n"]
        else
            curr$stdout.putString["Couldn't make it home\n"]
        end if

        for i : Integer <- self$times.lowerBound while i <= self$times.upperBound by i <- i + 1
            const ni : NodeInfo <- self$times.getElement[i]
            stdout.putstring
                [ "On node "
                || ni$nodeName
                || " ("
                || ni$nodeLNN.asString
                || "), the time was "
                || ni$localTime.asDate
                || "\n"
                ]
        end for
    end process
end TimeCollector
