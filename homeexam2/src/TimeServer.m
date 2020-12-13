% imports Replication.m

const Haltable <- typeobject Haltable
    operation halt
end Haltable

const TimeServer <- immutable object TimeServer
    export function getSignature -> [res : Signature]
        res <- typeobject TimeServer
            function getTimeOfDay -> [Time]
            operation setTimeOfDay[Time]
            operation addToState[Time]
            operation removeFromState[Time]
            function cloneMe -> [TimeServer]
        end TimeServer
    end getSignature

    export function create[initialTime : Time] -> [res : TimeServer]
        res <- object NewTimeServer
            attached field timeOfDay : Time <- initialTime

            export operation addToState[x : Time]
                self.setTimeOfDay[x]
            end addToState

            export operation removeFromState[x : Time]
                % noop
            end removeFromState

            export function cloneMe -> [res : TimeServer]
                res <- TimeServer.create[timeOfDay]
            end cloneMe
        end NewTimeServer
    end create
end TimeServer

const TimeSetter <- immutable object TimeSetter
    export function getSignature -> [res : Signature]
        res <- typeobject TimeSetter
            operation start
            operation halt
        end TimeSetter
    end getSignature

    export function create
        [ ts : State.of[TimeServer, Time]
        , loopDelay : Time
        ]
    -> [res : TimeSetter]
        res <- object NewTimeSetter
            var ref : Haltable <- nil
            export operation start
                ref <- object Ref
                    var continue : Boolean <- true
                    process
                        const home : Node <- locate self
                        loop
                            exit when !continue

                            const theTime <- home$timeOfDay
                            ts.addToState[theTime]

                            home.delay[loopDelay]
                        end loop
                    end process

                    export operation halt
                        continue <- false
                    end halt
                end Ref
            end start

            export operation halt
                ref.halt
            end halt
        end NewTimeSetter
    end create
end TimeSetter

const TimeGetter <- immutable object TimeGetter
    const TimeList <- Array.of[Time]

    export function getSignature -> [r : Signature]
        r <- typeobject TimeGetter
            operation start
            function stop -> [TimeList]
        end TimeGetter
    end getSignature

    export function create
        [ theTimeServerState : State.of[TimeServer, Time]
        , loopDelay : Time
        ]
    -> [res : TimeGetter]
        res <- object NewTimeGetter
            attached var ref : Haltable <- nil
            attached const times : TimeList <- TimeList.empty

            export operation start
                ref <- object Ref
                    var continue : Boolean <- true
                    process
                        const home <- locate self
                        loop
                            exit when !continue
                            home.delay[loopDelay]

                            const theTimeServer <- theTimeServerState$state
                            const res <- theTimeServer$timeOfDay
                            times.addUpper[res]
                        end loop
                    end process

                    export operation halt
                        continue <- false
                    end halt
                end Ref
            end start

            export function stop -> [res : TimeList]
                begin
                    ref.halt
                    res <- times
                    failure
                        res <- TimeList.empty
                    end failure
                end
            end stop
        end NewTimeGetter
    end create
end TimeGetter


const main <- object Main
    initially
        const home <- locate self
        const nodes <- home$activeNodes
        const numberOfNodes <- nodes.lowerBound + nodes.upperBound + 1
        const tsPicker <- ArrayUtils.of[TimeServerState]
        const theReplicator <- Replicator.of[TimeServer, Time]
        const TimeServerState <- State.of[TimeServer, Time]

        const ns <- TimeServer.create[home$timeOfDay]
        const theRealReplicas <- theReplicator.replicate[ns, numberOfNodes]
        const replicas : Array.of[TimeServerState] <-
            tsPicker.shuffle[theRealReplicas]

        const timeSettersReplica <- theRealReplicas.getElement[0]
        const theTimeSetter : TimeSetter <-
            TimeSetter.create[timeSettersReplica, Util.msToTime[400]]
        move theTimeSetter to timeSettersReplica
        theTimeSetter.start

        const refs <- Array.of[TimeGetter].empty
        for i : Integer <- replicas.lowerBound
        while i <= replicas.upperBound
        by i <- i + 1
            const theReplica <- replicas.getElement[i]
            const theLoopDelay <- Util.msToTime[500 + (i * 100)]
            const theTimeGetter : TimeGetter <-
                TimeGetter.create[theReplica, theLoopDelay]
            move theTimeGetter to theReplica
            theTimeGetter.start
            refs.addUpper[theTimeGetter]
        end for

        home.delay[Time.create[3, 0]]

        theTimeSetter.halt
        theReplicator.halt[replicas]
        for i : Integer <- refs.lowerBound
        while i <= refs.upperBound
        by i <- i + 1
            begin
                const theTimeGetter : TimeGetter <- refs.getElement[i]
                const res <- theTimeGetter.stop
                stdout.putstring["TimeGetter " || i.asString || "\n"]
                for j : Integer <- res.lowerBound
                while j <= res.upperBound
                by j <- j + 1
                    stdout.putstring[res.getElement[j].asString || "\n"]
                end for

                unavailable
                    stdout.putstring
                        [  "Lost contact with TimeGetter "
                        || i.asString
                        || "\n"
                        ]
                end unavailable
            end
            stdout.putstring["--------\n"]
        end for
    end initially
end Main
