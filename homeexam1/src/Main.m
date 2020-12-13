% imports Server
% imports Peer
% imports File
% imports Hash
% imports Util

const hardCodedFiles : Array.of[File] <- Array.of[File].empty
const foo <- object foo
    operation addFile[name : String, contents : String]
        hardCodedFiles.addUpper[File.create[DjbHash, name, contents]]
    end addFile
    initially
        self.addFile["Generic file", "File 1 contents"]
        self.addFile["Some other file", "Some other file contents"]
        self.addFile["Foobar", "Bazquux"]
        self.addFile["One of the oldest memes", "Kilroy was here"]
        self.addFile["Service announcement", "This is an important service announcement"]
        self.addFile["Skyrim", "Distributed Skyrim running in Emerald"]
        self.addFile["Eiffel 65 - I'm Blue (Da Ba Dee)", "I'm blue, da ba dee da ba daa"]
        self.addFile["The City in Germany that does not exist", "I don't remember the name of that city right now..."]
        self.addFile["What does the fox say?", "<unintelligible screeching>"]
        self.addFile["The Djb hashing algorithm", "Hah. Like I'm gonna recite the entire thing here and now."]
    end initially
end foo

const Prefixer <- immutable object Prefixer
    const PrefixerType <- immutable typeobject PrefixerType
        function withPrefix[String] -> [String]
        operation print[String]
        operation println[String]
    end PrefixerType

    export function getSignature -> [r : Signature]
        r <- PrefixerType
    end getSignature

    export function create[pfx : String] -> [res : PrefixerType]
        res <- immutable object NewPrefixer
            export function withPrefix[str : String] -> [res : String]
                res <- pfx || str
            end withPrefix

            export operation print[str : String]
                stdout.putstring[self.withPrefix[str]]
            end print

            export operation println[str : String]
                stdout.putstring[self.withPrefix[str] || "\n"]
            end println
        end NewPrefixer
    end create

    export function fromActorAndPeer
        [ pa : PeerActor
        , thePeer : Peer
        ]
    -> [res : PrefixerType]
        res <- self.create
            [  pa$actorType
            || "\t("
            || thePeer$peerID.asString
            || "): "
            ]
    end fromActorAndPeer
end Prefixer

% Should be possible to expose pickRandom as a generic array function, but I
% couldn't get the compiler to agree with me unless I wrapped pickRandom in
% this sort of arragement.
const RandomPicker <- immutable object RandomPickerBuilder
    export function of[itemType : Type] -> [res : NewRandomPickerType]
        forall itemType
        where ListType <- Array.of[itemType]
        where
            NewRandomPickerType <- immutable typeobject NewRandomPickerType
                function pickRandom[ListType] -> [itemType]
            end NewRandomPickerType

        res <- immutable object NewRandomPicker
            export function pickRandom[xs : ListType] -> [res : itemType]
                const home <- locate self
                const itemIndices <- xs.upperBound - xs.lowerBound
                if itemIndices = 0 then
                    res <- xs.getElement[0]
                    return
                end if
                const idx <- home$timeOfDay$microSeconds # itemIndices
                res <- xs.getElement[xs.lowerBound + idx]
            end pickRandom
        end NewRandomPicker
    end of
end RandomPickerBuilder

const PeerActor <- immutable typeobject PeerActor
    operation act[Peer]
    function getActorType -> [String]
    operation halt
end PeerActor

const PeerActorBuilder <- immutable typeobject PeerActorBuilder
    function create[Server] -> [PeerActor]
end PeerActorBuilder

% Attempts to fetch files.
const WantsFiles <- immutable object WantsFiles
    export function create[theServer : Server] -> [res : PeerActor]
        res <- immutable object NewGetter
            var doHalt : Boolean <- false

            export operation act[thePeer : Peer]
                const pr <- Prefixer.fromActorAndPeer[self, thePeer]
                loop
                    (locate self).delay[Time.create[3, 0]]
                    if doHalt then
                        pr.println["halting..."]
                        return
                    end if

                    const theFile <-
                        RandomPicker.of[File].pickRandom[hardCodedFiles]
                    const theMeta <- theFile$meta
                    const peers <- theServer.locateFileByName[theMeta$name]
                    if !peers.empty then
                        const otherPeer : Peer <-
                            RandomPicker.of[Peer].pickRandom[peers]
                        const downloadedFile <- thePeer.fetchFileFromPeer
                            [ theMeta
                            , otherPeer
                            ]
                        pr.println
                            [ "downloaded "
                            || downloadedFile$meta$name
                            || " from "
                            || otherPeer$peerID.asString
                            ]
                    end if
                end loop
            end act

            export operation halt
                doHalt <- true
            end halt

            export function getActorType -> [res : String]
                res <- "WantsFiles"
            end getActorType
        end NewGetter
    end create
end WantsFiles

% Starts with no files, but gets files over time.
const HasFiles <- immutable object HasFiles
    export function create[theServer : Server] -> [res : PeerActor]
        res <- immutable object NewGetter
            var doHalt : Boolean <- false

            export operation act[thePeer : Peer]
                const pr <- Prefixer.fromActorAndPeer[self, thePeer]
                loop
                    (locate self).delay[Time.create[2, 0]]
                    if doHalt then
                        pr.println["halting..."]
                        return
                    end if

                    const theFile <-
                        RandomPicker.of[File].pickRandom[hardCodedFiles]
                    thePeer.addFile[theFile]
                    pr.println["acquired " || theFile$meta$name]
                end loop
            end act

            export operation halt
                doHalt <- true
            end halt

            export function getActorType -> [res : String]
                res <- "HasFiles"
            end getActorType
        end NewGetter
    end create
end HasFiles

% Starts with all files, but loses them over time.
const LosesFiles <- immutable object LosesFiles
    export function create[theServer : Server] -> [res : PeerActor]
        res <- immutable object NewLosesFiles
            var doHalt : Boolean <- false

            export operation act[thePeer : Peer]
                const pr <- Prefixer.fromActorAndPeer[self, thePeer]
                const home : Node <- locate self
                for i : Integer <- hardCodedFiles.lowerBound
                while i <= hardCodedFiles.upperBound
                by i <- i + 1
                    thePeer.addFile[hardCodedFiles.getElement[i]]
                end for
                loop
                    home.delay[Time.create[2, 0]]
                    if doHalt then
                        pr.println["halting..."]
                        return
                    end if

                    begin
                        const files <- thePeer$files
                        const theFile <- RandomPicker.of[File].pickRandom[files]
                        thePeer.dropFile[theFile$meta]
                        pr.println["dropped file: " || theFile$meta$name]
                        failure
                            pr.println["no files to drop"]
                        end failure
                    end
                end loop
            end act

            export operation halt
                doHalt <- true
            end halt

            export function getActorType -> [res : String]
                res <- "LosesFiles"
            end getActorType
        end NewLosesFiles
    end create
end LosesFiles

% Used to run the various PeerActor implementations above in a separate process
% after they have been moved to a different node.
const ActorWorker <- immutable object ActorWorker
    const ActorWorkerType <- immutable typeobject ActorWorkerType
        operation start
        function getActorType -> [String]
        operation halt
    end ActorWorkerType

    export function getSignature -> [r : Signature]
        r <- ActorWorkerType
    end getSignature

    export function create
        [ thePeer : Peer
        , pa : PeerActor
        ]
    -> [res : ActorWorkerType]
        res <- immutable object NewActorWorker
            var foo : Any
            export operation start
                foo <- object ProcessHolder
                    process
                        pa.act[thePeer]
                    end process
                end ProcessHolder
            end start

            export function getActorType -> [res : String]
                res <- pa$actorType
            end getActorType

            export operation halt
                pa.halt
            end halt
        end NewActorWorker
    end create
end ActorWorker

const main <- object main
    function max[x : Integer, y : Integer] -> [res : Integer]
        if x > y then
            res <- x
        else
            res <- y
        end if
    end max

    function min[x : Integer, y : Integer] -> [res : Integer]
        if x < y then
            res <- x
        else
            res <- y
        end if
    end min

    function pickNode
        [ i : Integer
        , theNodes : NodeList
        ]
    -> [res : NodeListElement]
        const numItems <- theNodes.upperBound - theNodes.lowerBound + 1
        const wrappedIndex <- i # numItems
        res <- theNodes.getElement[wrappedIndex + theNodes.lowerBound]
    end pickNode

    operation bootstrapPeer
        [ theServer : Server
        , actorBuilder : PeerActorBuilder
        , targetNode : Node
        ]
    -> [res : ActorWorker]
        const thePeer <- PeerBuilder.create[stdout, theServer]
        thePeer.initialize
        const theActor <- actorBuilder.create[theServer]
        const theWorker <- ActorWorker.create[thePeer, theActor]
        move thePeer to targetNode
        move theActor to targetNode
        move theWorker to targetNode
        theWorker.start
        res <- theWorker
    end bootstrapPeer

    initially
        const pr <- Prefixer.create["Main: "]
        const home <- locate self
        const theServer : Server <- Server.create[stdout]
        const theCleaner <- ServerCleaner.create[theServer]

        const activeNodes : NodeList <- home$activeNodes
        const numActiveNodes : Integer <- activeNodes.upperBound + 1
        pr.println
            [  "there are "
            || numActiveNodes.asString
            || " active nodes available"
            ]

        const peerActorBuilders <- Array.of[PeerActorBuilder].empty
        peerActorBuilders.addUpper[HasFiles]
        peerActorBuilders.addUpper[WantsFiles]
        peerActorBuilders.addUpper[LosesFiles]
        peerActorBuilders.addUpper[HasFiles]
        peerActorBuilders.addUpper[WantsFiles]

        const workers : Array.of[ActorWorker] <- Array.of[ActorWorker].empty
        var idx : Integer <- 0

        for i : Integer <- peerActorBuilders.lowerBound
        while i <= peerActorBuilders.upperBound
        by i <- i + 1
            const nodeToUse <- self.pickNode[i, activeNodes]$theNode
            const builder <- peerActorBuilders.getElement[i]
            const theWorker <- self.bootstrapPeer[theServer, builder, nodeToUse]
            workers.addUpper[theWorker]
            pr.println
                [  "Started a "
                || theWorker$actorType
                ]
        end for

        % Wait for the peers to do some work.
        home.delay[Time.create[20, 0]]

        for i : Integer <- workers.lowerBound
        while i <= workers.upperBound
        by i <- i + 1
            workers.getElement[i].halt
        end for
        theCleaner.halt
        home.delay[Time.create[6, 0]]
        pr.println["all workers halted\n"]

        pr.println[theServer.stringifyState]
    end initially
end main
