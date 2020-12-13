% imports File
% imports Peer

const FileMetaList <- Array.of[FileMeta]
const PeerList <- Array.of[Peer]

const PeerRecord <- immutable object PeerRecord
    const PeerRecordType <- immutable typeobject PeerRecordType
        function getThePeer -> [Peer]
        function getFiles -> [FileMetaList]
        function hasFile[FileMeta] -> [Boolean]
        function hasFileWithName[String] -> [Boolean]
        operation addFile[FileMeta]
        operation removeFile[FileMeta]
        function stringifyState -> [String]
    end PeerRecordType

    export function getSignature -> [r : Signature]
        r <- PeerRecordType
    end getSignature

    export function create[recordPeer : Peer] -> [res : PeerRecord]
        res <- immutable object NewPeerRecord
            const field thePeer : Peer <- recordPeer
            attached field files : FileMetaList <- FileMetaList.empty

            export operation addFile[theFileMeta : FileMeta]
                files.addUpper[theFileMeta]
            end addFile

            export function hasFile[theFileMeta : FileMeta] -> [res : Boolean]
                res <- false
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    if files.getElement[i] == theFileMeta then
                        res <- true
                        return
                    end if
                end for
            end hasFile

            export function hasFileWithName[theName : String] -> [res : Boolean]
                res <- false
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    begin
                        const theMeta <- files.getElement[i]
                        const r <- theMeta$name.str[theName]
                        if r > 0 | r >= 0  then
                            res <- true
                            return
                        end if
                        failure
                        end failure
                    end
                end for
            end hasFileWithName

            export operation removeFile[metaToRemove : FileMeta]
                const temp <- FileMetaList.empty
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    const theMeta <- files.getElement[i]
                    if theMeta != metaToRemove then
                        temp.addUpper[theMeta]
                    end if
                end for
                files <- temp
            end removeFile

            export function stringifyState -> [res : String]
                res <-
                    "Peer record "
                    || thePeer$peerID.asString
                    || ":\n\tregistered files: "
                if files.empty then
                    res <- res || "no registered files"
                else
                    res <- res || "\n\t\t"
                    for i : Integer <- files.lowerBound
                    while i <= files.upperBound
                    by i <- i + 1
                        res <- res || files.getElement[i].stringifyState
                        if i != files.upperBound then
                            res <- res || "\n\t\t"
                        end if
                    end for
                end if

                res <- res || "\n\tPeer state: " || thePeer.stringifyState
            end stringifyState
        end NewPeerRecord
    end create
end PeerRecord

const PeerRecordList <- Array.of[PeerRecord]

const Server <- immutable object Server
    const ServerType <- typeobject ServerType
        operation registerNewFile[Peer, FileMeta]
        function locateFile[FileMeta] -> [PeerList]
        function locateFileByName[String] -> [PeerList]
        operation fileRemoved[Peer, FileMeta]
        operation newPeer[Peer]
        operation getFiles -> [FileMetaList]
        function stringifyState -> [String]
        function getPeersAndMakeBusy -> [PeerRecordList]
        operation setPeersAndSignal[PeerRecordList]
    end ServerType

    export function getSignature -> [r : Signature]
        r <- ServerType
    end getSignature

    export function create[output : CanPutString] -> [res : Server]
        forall CanPutString
        suchThat CanPutString *>
            typeobject CanPutString
                operation putString[String]
            end CanPutString

        res <- monitor object NewServer
            attached field peers : PeerRecordList <- PeerRecordList.empty
            attached var peersAreBusy : Boolean <- false
            attached const peersAreReady : Condition <- Condition.create

            operation awaitPeers
                if peersAreBusy then
                    wait peersAreReady
                end if
                peersAreBusy <- true
            end awaitPeers

            operation signalPeers
                peersAreBusy <- false
                signal peersAreReady
            end signalPeers

            export function getPeersAndMakeBusy -> [res : PeerRecordList]
                self.awaitPeers
                res <- peers
            end getPeersAndMakeBusy

            export operation setPeersAndSignal[ps : PeerRecordList]
                peers <- ps
                self.signalPeers
            end setPeersAndSignal

            function findPeerRecord[thePeer : Peer] -> [res : PeerRecord]
                for i : Integer <- peers.lowerBound
                while i <= peers.upperBound
                by i <- i + 1
                    const theRecord : PeerRecord <- peers.getElement[i]
                    if theRecord$thePeer == thePeer then
                        res <- theRecord
                        exit
                    end if
                end for
            end findPeerRecord

            export function getFiles -> [res : FileMetaList]
                res <- FileMetaList.empty

                for i : Integer <- peers.lowerBound
                while i <= peers.upperBound
                by i <- i + 1
                    const theRecord <- peers.getElement[i]
                    res <- res.catenate[theRecord$files]
                end for
            end getFiles

            export operation registerNewFile[thePeer : Peer, newMeta : FileMeta]
                self.awaitPeers
                const theRecord <- self.findPeerRecord[thePeer]
                const fileMetas <- theRecord$files
                var doAdd : Boolean <- true
                for i : Integer <- fileMetas.lowerBound
                while i <= fileMetas.upperBound
                by i <- i + 1
                    const theMeta : FileMeta <- fileMetas.getElement[i]
                    if theMeta = newMeta then
                        doAdd <- false
                        exit
                    end if
                end for

                % Utilizing the mutability of Arrays, we only need to add the
                % new file metadata to the array. This comment is mostly for
                % myself, since I'm more accustomed to FP at this point, where
                % you wouldn't do it this way.
                if doAdd then
                    fileMetas.addUpper[newMeta]
                end if

                self.signalPeers
            end registerNewFile

            export function locateFile[meta : FileMeta] -> [res : PeerList]
                res <- PeerList.empty
                self.awaitPeers

                for i : Integer <- peers.lowerBound
                while i <= peers.upperBound
                by i <- i + 1
                    const theRecord : PeerRecord <- peers.getElement[i]
                    if theRecord.hasFile[meta] then
                        res.addUpper[theRecord$thePeer]
                    end if
                end for

                self.signalPeers
            end locateFile

            export function locateFileByName[theName : String] -> [res : PeerList]
                res <- PeerList.empty
                self.awaitPeers

                for i : Integer <- peers.lowerBound
                while i <= peers.upperBound
                by i <- i + 1
                    const theRecord : PeerRecord <- peers.getElement[i]
                    if theRecord.hasFileWithName[theName] then
                        res.addUpper[theRecord$thePeer]
                    end if
                end for

                self.signalPeers
            end locateFileByName

            export operation fileRemoved[thePeer : Peer, metaToRemove : FileMeta]
                self.awaitPeers

                for i : Integer <- peers.lowerBound
                while i <= peers.upperBound
                by i <- i + 1
                    const theRecord : PeerRecord <- peers.getElement[i]
                    if theRecord$thePeer = thePeer then
                        theRecord.removeFile[metaToRemove]
                        exit
                    end if
                end for

                self.signalPeers
            end fileRemoved

            export operation newPeer[p : Peer]
                self.awaitPeers

                peers.addUpper[PeerRecord.create[p]]

                self.signalPeers
            end newPeer

            export function stringifyState -> [res : String]
                res <- "Server peer records: "

                if peers.empty then
                    res <- res || "no peers registered"
                else
                    res <- res || "\n\n"
                    for i : Integer <- peers.lowerBound
                    while i <= peers.upperBound
                    by i <- i + 1
                        res <- res || peers.getElement[i].stringifyState
                        if i != peers.upperBound then
                            res <- res || "\n\n"
                        end if
                    end for
                end if
            end stringifyState

        end NewServer
    end create
end Server
export Server

const ServerCleaner <- immutable object ServerCleaner
    export function getSignature -> [r : Signature]
        r <- typeobject ServerCleanerType
            operation halt
        end ServerCleanerType
    end getSignature
    export function create[theServer : Server] -> [res : ServerCleaner]
        res <- object NewServerCleaner
            var doHalt : Boolean <- false

            export operation halt
                doHalt <- true
            end halt

            % This process periodically checks the availability of the peers.
            process
                const home <- locate self
                loop
                    if doHalt then
                        return
                    end if

                    home.delay[Time.create[5, 0]]
                    const recordsToKeep <- PeerRecordList.empty
                    const peers <- theServer.getPeersAndMakeBusy
                    for i : Integer <- peers.lowerBound
                    while i <= peers.upperBound
                    by i <- i + 1
                        begin
                            const theRecord <- peers.getElement[i]
                            const thePeer <- theRecord$thePeer
                            const theNode <- locate thePeer
                            % If we've come this far without encountering an
                            % "unavailable" error, then the peer is still up.
                            recordsToKeep.addUpper[theRecord]
                            unavailable
                            end unavailable
                        end
                    end for

                    theServer.setPeersAndSignal[recordsToKeep]
                end loop
            end process
        end NewServerCleaner
    end create
end ServerCleaner
export ServerCleaner
