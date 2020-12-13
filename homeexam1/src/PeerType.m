% Because Server depends on Peer, and Peer depends on Server, we separate out
% the Peer type so that Server can be compiled before Peer, solving this rather
% circular dependency.

const Peer <- immutable typeobject Peer
    function getPeerID -> [Time]
    function getFiles -> [Array.of[File]]
    function getFileMeta -> [Array.of[FileMeta]]
    function hasFile[FileMeta] -> [Boolean]
    function requestFile[FileMeta] -> [File]
    function =[Peer] -> [Boolean]

    function stringifyState -> [String]
    operation initialize
    operation addFile[File]
    function fetchFileFromPeer[FileMeta, Peer] -> [File]
    operation dropFile[FileMeta]
end Peer
export Peer
