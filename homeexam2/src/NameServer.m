% imports Replication.m

const NSEntry <- immutable object NSEntry
    export function getSignature -> [r : Signature]
        r <- immutable typeobject NSEntryType
            function getName -> [String]
            function getContents -> [String]
            function asString -> [String]
            function =[NSEntry] -> [Boolean]
        end NSEntryType
    end getSignature

    export function create[theName : String, theContents : String] -> [res : NSEntry]
        res <- immutable object NSEntry
            attached field name : String <- theName
            attached field contents : String <- theContents

            export function asString -> [res : String]
                res <- "[ Name: " || name || ", Contents: " || contents || " ]"
            end asString

            export function =[otherNSE : NSELike] -> [res : Boolean]
                forall NSELike
                suchThat NSELike *> typeobject NSELike
                    function getName -> [String]
                    function getContents -> [String]
                end NSELike

                res <- name = otherNSE$name & contents = otherNSE$contents
            end =
        end NSEntry
    end create
end NSEntry

const NameServer <- immutable object NameServer
    const NameServerType <- immutable typeobject NameServerType
        function lookup[String] -> [NSEntry]
        operation add[NSEntry]
        operation addToState[NSEntry]
        operation removeFromState[NSEntry]
        function cloneMe -> [NameServer]
    end NameServerType

    export function getSignature -> [res : Signature]
        res <- NameServerType
    end getSignature

    export function create -> [res : NameServer]
        where
            NSEntryList <- Array.of[NSEntry]

        res <- immutable object NewNameServer
            attached var coll : NSEntryList <- NSEntryList.empty

            export function lookup[x : String] -> [res : NSEntry]
                for i : Integer <- coll.lowerBound
                while i <= coll.upperBound
                by i <- i + 1
                    const item : NSEntry <- coll.getElement[i]
                    if item$name = x then
                        res <- item
                        return
                    end if
                end for
            end lookup

            export operation add[x : NSEntry]
                coll.addUpper[x]
            end add

            export operation addToState[x : NSEntry]
                self.add[x]
            end addToState

            export operation removeFromState[x : NSEntry]
                const res <- NSEntryList.empty
                for i : Integer <- coll.lowerBound
                while i <= coll.upperBound
                by i <- i + 1
                    const item <- coll.getElement[i]
                    if !(item == x) then
                        res.addUpper[item]
                    end if
                end for
                coll <- res
            end removeFromState

            export function cloneMe -> [res : NameServer]
                res <- NameServer.create
                for i : Integer <- coll.lowerBound
                while i <= coll.upperBound
                by i <- i + 1
                    const item <- coll.getElement[i]
                    res.add[item]
                end for
            end cloneMe
        end NewNameServer
    end create
end NameServer

const Client <- immutable object Client
    const NSEntryList <- Array.of[NSEntry]
    const ResultEntry <- Pair.of[String, NSEntry]
    const ResultList <- Array.of[ResultEntry]

    export function getSignature -> [r : Signature]
        r <- immutable typeobject ClientType
            operation start
            function stop -> [ResultList]
        end ClientType
    end getSignature

    export function create
        [ theNSState : State.of[NameServer, NSEntry]
        , nseToLookup : NSEntry
        , ownNSE : NSEntry
        , loopDelay : Time
        , out : OutStream
        ]
    -> [res : Client]
        where
            Haltable <- typeobject Haltable
                operation halt
            end Haltable

        res <- immutable object NewClient
            attached var ref : Haltable <- nil
            attached const fetched : ResultList <- ResultList.empty

            export operation start
                ref <- object Ref
                    var added : Boolean <- false
                    var continue : Boolean <- true
                    var count : Integer <- 0
                    const loopUntil : Integer <- (loopDelay$microseconds # 4) + 6
                    process
                        const home <- locate self
                        loop
                            exit when !continue

                            const theNameServer <- theNSState$state
                            home.delay[loopDelay]
                            if !added & loopUntil = count then
                                theNSState.addToState[ownNSE]
                                added <- true
                            else
                                count <- count + 1
                            end if

                            begin
                                const res <-
                                    theNameServer.lookup[nseToLookup$name]
                                % I have trouble finding how to check whether a
                                % given object is Nil. To ensure we don't add a
                                % bunch of Nils to our collection of looked-up
                                % objects, we force the Nil by calling the
                                % getName operation on the NSEntry type,
                                % catching the failure if the object is indeed
                                % Nil.
                                const res_ <- res$name
                                fetched.addUpper
                                    [ Pair.of[String, NSEntry]
                                        .create["success", res]
                                    ]
                                failure
                                    fetched.addUpper
                                        [ Pair.of[String, NSEntry]
                                            .create["failed", nseToLookup]
                                        ]
                                end failure
                            end
                        end loop
                    end process

                    export operation halt
                        continue <- false
                    end halt
                end Ref
            end start

            export function stop -> [res : ResultList]
                ref.halt
                res <- fetched
            end stop
        end NewClient
    end create
end Client

const main <- object Main
    initially
        const home <- locate self
        const nodes <- home$activeNodes
        const numberOfNodes <- nodes.lowerBound + nodes.upperBound + 1
        const ns <- NameServer.create
        const NameServerState <- State.of[NameServer, NSEntry]
        const theReplicator <- Replicator.of[NameServer, NSEntry]
        const replicas : Array.of[NameServerState] <-
            theReplicator.replicate[ns, numberOfNodes]

        const fooNSE : NSEntry <- NSEntry.create["Foo", "Foobar"]
        const barNSE : NSEntry <- NSEntry.create["Bar", "Barfoo"]
        const bazNSE : NSEntry <- NSEntry.create["Baz", "Bazquux"]
        const quuxNSE : NSEntry <- NSEntry.create["Quux", "Quuxbaz"]

        const NSEs : Array.of[NSEntry] <- Array.of[NSEntry].empty
        NSEs.addUpper[fooNSE]
        NSEs.addUpper[barNSE]
        NSEs.addUpper[bazNSE]
        NSEs.addUpper[quuxNSE]

        const refs <- Array.of[Client].empty
        for i : Integer <- nodes.lowerBound
        while i <= nodes.upperBound
        by i <- i + 1
            const otherNode <- nodes.getElement[i]$theNode
            const theReplica <-
                ArrayUtils.of[NameServerState].getElementOrWrap[i, replicas]
            const theLoopDelay <- Util.msToTime[100 + (10 * i)]
            const theNSE <- ArrayUtils.of[NSEntry].getElementOrWrap[i, NSEs]
            const otherNSE <-
                ArrayUtils.of[NSEntry].getElementOrWrap[(i + 1), NSEs]
            const theClient : Client <- Client.create
                [ theReplica
                , otherNSE
                , theNSE
                , theLoopDelay
                , stdout
                ]
            theClient.start

            refs.addUpper[theClient]
        end for

        home.delay[Time.create[2, 0]]

        theReplicator.halt[replicas]
        for i : Integer <- refs.lowerBound
        while i <= refs.upperBound
        by i <- i + 1
            begin
                const theClient : Client <- refs.getElement[i]
                const res <- theClient.stop
                stdout.putstring["Client " || i.asString || "\n"]
                for j : Integer <- res.lowerBound while j <= res.upperBound by j <- j + 1
                    const p <- res.getElement[j]
                    stdout.putstring[p$first || ", " || p$second.asString || "\n"]
                end for

                unavailable
                    stdout.putstring["Lost contact with Client " || i.asString || "\n"]
                end unavailable
            end
            stdout.putstring["--------\n"]
        end for
    end initially
end Main
