% imports File

const PeerBuilder <- immutable object PeerBuilder
    export function create[output : CanPrint, theServer : Server] -> [res : Peer]
        forall CanPrint
        suchThat CanPrint *>
            typeobject CanPrint
                operation putstring[String]
            end CanPrint
        where FileList <- Array.of[File]

        res <- immutable object NewPeer
            const indexServer : Server <- theServer
            attached const field peerID : Time <- (locate self)$timeOfDay
            attached field files : FileList <- FileList.empty
            attached const field downloadedFiles : FileList <- FileList.empty

            export function getFileMeta -> [res : Array.of[FileMeta]]
                res <- Array.of[FileMeta].empty
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    res.addUpper[files.getElement[i]$meta]
                end for
            end getFileMeta

            export function hasFile[meta : FileMeta] -> [res : Boolean]
                res <- false
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    if files.getElement[i]$meta == meta then
                        res <- true
                        return
                    end if
                end for
            end hasFile

            export function requestFile[meta : FileMeta] -> [res : File]
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    const theFile : File <- files.getElement[i]
                    if theFile$meta == meta then
                        res <- theFile
                        exit
                    end if
                end for
            end requestFile

            export operation initialize
                indexServer.newPeer[self]
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    indexServer.registerNewFile[self, files.getElement[i]$meta]
                end for
            end initialize

            export operation addFile[theFile : File]
                move theFile to (locate self)
                files.addUpper[theFile]
                indexServer.registerNewFile[self, theFile$meta]
            end addFile

            export function =[otherPeer : Peer] -> [res : Boolean]
                res <- peerID = otherPeer$peerID
            end =

            export function fetchFileFromPeer
                [ theMeta : FileMeta
                , otherPeer : Peer
                ]
            -> [res : File]
                res <- otherPeer.requestFile[theMeta]
                downloadedFiles.addUpper[res]
                self.addFile[res]
            end fetchFileFromPeer

            export operation dropFile[theMeta : FileMeta]
                const temp <- FileList.empty
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    const theFile <- files.getElement[i]
                    if theFile$meta != theMeta then
                        temp.addUpper[theFile]
                    end if
                end for
                files <- temp
                theServer.fileRemoved[self, theMeta]
            end dropFile

            export function stringifyState -> [res : String]
                res <- "Peer " || peerID.asString || ":"
                res <- res || "\n\town files:" || self.stringifyFiles[files]
                res <- res || "\n\tdownloaded files:" || self.stringifyFiles[downloadedFiles]
            end stringifyState

            function stringifyFiles[filesToStringify : Array.of[File]] -> [res : String]
                if filesToStringify.empty then
                    res <- " no files"
                    return
                end if

                res <- ""
                for i : Integer <- files.lowerBound
                while i <= files.upperBound
                by i <- i + 1
                    res <-
                        res
                        || "\n\t\tFile "
                        || i.asString
                        || ": "
                        || files.getElement[i].stringifyState
                end for
            end stringifyFiles
        end NewPeer
    end create
end PeerBuilder
export PeerBuilder
