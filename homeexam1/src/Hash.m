% imports Util

const Hasher <- typeobject Hasher
    function hash[ input : String ] -> [ hash : Integer ]
end Hasher
export Hasher

%% This is how java.lang.String's "hashCode" method is implemented. It is
% exceedingly prone to collisions, and should probably not be used.
const JavaHash : Hasher <- object JavaHash
    export function hash[ input : String ] -> [ hash : Integer ]
        hash <- 0
        const n <- input.length

        for i : Integer <- 0 while i < input.length by i <- i + 1
            const c : Integer <- input.getElement[i].hash
            hash <- hash + (c + Util.power[31, input.length - i])
        end for
    end hash
end JavaHash
export JavaHash

%% Dan Bernsteins hash function, djb2a.
% Reference: http://www.cse.yorku.ca/~oz/hash.html and
% https://github.com/sindresorhus/djb2a/blob/master/index.js.
const DjbHash : Hasher <- object DjbHash
    const MAGIC_CONSTANT : Integer <- 5381
    export function hash[ input : String ] -> [ hash : Integer ]
        hash <- MAGIC_CONSTANT

        for i : Integer <- 0 while i < input.length by i <- i + 1
            const c : Integer <- input.getElement[i].hash
            hash <- Util.bitXor[(hash * 33), c]
        end for
    end hash
end DjbHash
export DjbHash
