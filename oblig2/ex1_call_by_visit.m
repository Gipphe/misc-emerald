const PayloadInstance <- typeobject PayloadInstance
    function getPayload -> [ res : Array.of[Integer] ]
end PayloadInstance

const ConsumerInstance <- typeobject ConsumerInstance
    operation callByVisit[calls : Integer, payload : PayloadInstance]
    operation directCall[calls : Integer, payload : PayloadInstance]
end ConsumerInstance

const PayloadCreator <- object PayloadCreator
    export operation create[size : Integer] -> [ res : PayloadInstance ]
        res <- object NewPayload
            attached const field payload : Array.of[Integer] <- Array.of[Integer].create[size]
            initially
                for i: Integer <- 0 while i < size by i <- i + 1
                    self$payload.setElement[i, i]
                end for
            end initially
        end NewPayload
    end create
end PayloadCreator

const ConsumerCreator <- object ConsumerCreator
    export operation create -> [res : ConsumerInstance]
        res <- object NewConsumer
            export operation callByVisit[calls : Integer, payload : PayloadInstance]
                var list : Array.of[Integer]
                for i : Integer <- 0 while i < calls by i <- i + 1
                    list <- payload$payload
                end for
                if calls > 0 then
                    stdout.putstring["Called by visit with list of size " || (list.upperBound + 1).asString || " for " || calls.asString || " calls\n"]
                else
                    stdout.putstring["Called by visit with 0 calls\n"]
                end if
            end callByVisit

            export operation directCall[calls : Integer, payload : PayloadInstance]
                var list : Array.of[Integer]
                for i : Integer <- 0 while i < calls by i <- i + 1
                    list <- payload$payload
                end for
                if calls > 0 then
                    stdout.putstring["Direct called with list of size " || (list.upperBound + 1).asString || " for " || calls.asString || " calls\n"]
                else
                    stdout.putstring["Direct called with 0 calls\n"]
                end if
            end directCall
        end NewConsumer
    end create
end ConsumerCreator

const main <- object main
    operation moveConsumerAway[consumer : ConsumerInstance]
        const home : Node <- locate self
        const nodes : NodeList <- home$activeNodes
        const topNode : Node <- (nodes.getElement[nodes.upperBound]).getTheNode
        const bottomNode : Node <- (nodes.getElement[nodes.lowerBound]).getTheNode
        var otherNode : Node
        % If the top node is home, then the bottom node is not because home can
        % only be one node, unless there is only 1 active node, in which case
        % this whole analysis falls apart... We only want the consumer to be on
        % some other node than home. Exactly which node is insignificant for
        % this analysis. And we check it this way because the language report
        % does not specify whether the getActiveNodes operation has self's node
        % as the first element, so we cannot know whether it is the first or
        % the last one, but we know for certain it can't be both if we have
        % more than 1 active node!
        if topNode$LNN != home$LNN then
            otherNode <- topNode
        else
            otherNode <- bottomNode
        end if
        stdout.putstring["Moving consumer to " || otherNode$name || "\n\n"]
        move consumer to otherNode
    end moveConsumerAway

    operation measureCallByVisit[home : Node, calls : Integer, payload : PayloadInstance, consumer : ConsumerInstance] -> [res : Time]
        var startTime : Time
        var endTime : Time
        startTime <- home$timeOfDay
        move payload to consumer
        consumer.callByVisit[calls, payload]
        move payload to home
        endTime <- home$timeOfDay
        res <- endTime - startTime
    end measureCallByVisit

    operation measureDirectCall[home : Node, calls : Integer, payload : PayloadInstance, consumer : ConsumerInstance] -> [res : Time]
        var startTime : Time
        var endTime : Time
        startTime <- home$timeOfDay
        consumer.directCall[calls, payload]
        endTime <- home$timeOfDay
        res <- endTime - startTime
    end measureDirectCall

    initially
        const home : Node <- locate self
        const sizes <- Array.of[Integer].empty
        const consumer : ConsumerInstance <- ConsumerCreator.create
        sizes.addUpper[50]
        sizes.addUpper[100]
        sizes.addUpper[500]
        sizes.addUpper[1000]
        sizes.addUpper[10000]

        self.moveConsumerAway[consumer]

        for i : Integer <- sizes.lowerBound while i <= sizes.upperBound by i <- i + 1
            const size <- sizes.getElement[i]
            const payload : PayloadInstance <- PayloadCreator.create[size]
            const oneBillion : Integer <- 1000000000
            var callByVisitTime : Time
            var directCallTime : Time
            var calls : Integer <- 0
            var metBreakpoint : Boolean <- false

            loop
                callByVisitTime <- self.measureCallByVisit[home, calls, payload, consumer]
                directCallTime <- self.measureDirectCall[home, calls, payload, consumer]
                metBreakpoint <- callByVisitTime < directCallTime
                % If we ever reach 1 billion calls, there is likely some
                % programming error somewhere, but Moore's law suggests we
                % guard against cases where we end up in an infinite loop.
                exit when metBreakpoint | (calls > oneBillion)
                % Important to increment calls only if the break-point has not
                % been found yet. Keeping the exit statement above at the
                % bottom of the loop ensures calls is incremented one time too
                % many.
                calls <- calls + 1
            end loop

            stdout.putstring["Size " || size.asString || " callByVisit time: " || callByVisitTime.asString || "\n"]
            stdout.putstring["Size " || size.asString || " directCall time: " || directCallTime.asString || "\n"]

            if metBreakpoint then
                stdout.putstring["For the list size " || size.asString || ", the break-point is " || calls.asString || " calls\n\n"]
            else
                stdout.putstring["After " || oneBillion.asString || " calls, we could not find the break-point for size " || size.asString || "...\n\n"]
            end if
        end for
    end initially
end main
