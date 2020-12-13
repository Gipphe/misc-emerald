% imports Hash

const FileMeta <- immutable object FileMeta
    const FileMetaType <- immutable typeobject FileMetaType
        function getName -> [String]
        function getHash -> [Integer]
        function =[FileMeta] -> [Boolean]
        function !=[FileMeta] -> [Boolean]
        function stringifyState -> [String]
    end FileMetaType

    export function getSignature -> [r : Signature]
        r <- FileMetaType
    end getSignature

    export function create
        [ theHasher : Hasher
        , theName : String
        , theContents : String
        ]
    -> [res : FileMeta]
        res <- immutable object NewFileMeta
            const field name : String <- theName
            const field hash : Integer <- theHasher.hash[theContents]

            export function =[otherMeta : FileMeta] -> [res : Boolean]
                res <- hash = otherMeta$hash
            end =

            export function !=[otherMeta : FileMeta] -> [res : Boolean]
                res <- !(self = otherMeta)
            end !=

            export function stringifyState -> [res : String]
                res <-
                    "File name: "
                    || name
                    || ", File hash: "
                    || hash.asString
            end stringifyState
        end NewFileMeta
    end create
end FileMeta
export FileMeta

const File <- immutable object File
    const FileType <- immutable typeobject FileType
        function getMeta -> [FileMeta]
        function getContents -> [String]
        function =[File] -> [Boolean]
        function !=[File] -> [Boolean]
        function stringifyState -> [String]
    end FileType

    export function getSignature -> [r : Signature]
        r <- FileType
    end getSignature

    export function create
        [ theHasher : Hasher
        , theName : String
        , theContents : String
        ]
    -> [res : File]
        res <- immutable object NewFile
            const field meta : FileMeta <-
                FileMeta.create[theHasher, theName, theContents]
            const field contents : String <- theContents

            export function =[otherFile : File] -> [res : Boolean]
                res <- meta = otherFile$meta
            end =

            export function !=[otherFile : File] -> [res : Boolean]
                res <- !(self = otherFile)
            end !=

            export function stringifyState -> [res : String]
                res <-
                    meta.stringifyState
                    || ", File contents length: "
                    || contents.length.asString
            end stringifyState
        end NewFile
    end create
end File
export File
