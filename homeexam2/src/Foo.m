const ArrayOf <- immutable object ArrayOf
    export function unary[typeA : Type] -> [res : UnaryArrayOf]
        forall typeA
        where
            Consumer <- typeobject Consumer
                operation call[typeA]
            end Consumer
        where
            UnaryArrayOf <- immutable typeobject UnaryArrayOf
                operation forEach[Consumer, Array.of[typeA]]
            end UnaryArrayOf

        res <- immutable object UnaryArrayOf
            export operation forEach[f : Consumer, xs : Array.of[typeA]]
                for i : Integer <- xs.lowerBound
                while i <= xs.upperBound
                by i <- i + 1
                    f.call[xs.getElement[i]]
                end for
            end forEach

        end UnaryArrayOf
    end unary

    export function binary[typeA : Type, typeB : Type] -> [res : BinaryArrayOf]
        forall typeA
        forall typeB
        where
            Arrow <- typeobject Arrow
                function call[typeA] -> [typeB]
            end Arrow
        where
            BinaryArrayOf <- immutable typeobject BinaryArrayOf
                function map[Arrow, Array.of[typeA]] -> [Array.of[typeB]]
            end BinaryArrayOf

        res <- immutable object BinaryArrayOf
            export function map[f : Arrow, xs : Array.of[typeA]] -> [res : Array.of[typeB]]
                res <- Array.of[typeB].empty
                for i : Integer <- xs.lowerBound
                while i <= xs.upperBound
                by i <- i + 1
                    res.addUpper[f.call[xs.getElement[i]]]
                end for
            end map
        end BinaryArrayOf
    end binary
end ArrayOf

const Util <- immutable object Util
    export function wrapInteger[x : Integer, lowerBound : Integer, upperBound : Integer] -> [res : Integer]
        res <- x # (upperBound - lowerBound + 1)
    end wrapInteger

    export function msToTime[x : Integer] -> [res : Time]
        const seconds <- x / 1000
        const ms <- x # 1000
        res <- Time.create[seconds, ms * 1000]
    end msToTime
end Util
export Util

const ArrayUtils <- immutable object ArrayUtils
    export function of[itemType : Type] -> [res : NewArrayUtilsType]
        forall itemType
        where ListType <- Array.of[itemType]
        where
            NewArrayUtilsType <- immutable typeobject NewArrayUtilsType
                function pickRandom[ListType] -> [itemType]
                function shuffle[ListType] -> [ListType]
                function getElementOrWrap[Integer, ListType] -> [itemType]
            end NewArrayUtilsType

        res <- immutable object NewArrayUtils
            export function pickRandom[xs : ListType] -> [res : itemType]
                const home <- locate self
                const itemIndices <- xs.upperBound - xs.lowerBound
                if itemIndices = 0 then
                    res <- xs.getElement[0]
                    return
                end if
                const ms <- home$timeOfDay$microSeconds
                const idx <- (ms + ms * 31) # (itemIndices + 1)
                res <- xs.getElement[xs.lowerBound + idx]
            end pickRandom

            % Creates a copy of the passed array, shuffles the copy, and
            % returns that shuffled copy.
            export function shuffle[xs : ListType] -> [res : ListType]
                res <- xs.catenate[Array.of[itemType].empty]
                const home : Node <- locate self
                const len : Integer <- xs.lowerBound + xs.upperBound + 1

                for i : Integer <- xs.lowerBound
                while i <= xs.upperBound
                by i <- i + 1
                    const rng <- home$timeOfDay$microSeconds # len
                    self.swap[res, i, rng]
                end for
            end shuffle

            operation swap[xs : ListType, x : Integer, y : Integer]
                const temp : itemType <- xs.getElement[x]
                xs.setElement[x, xs.getElement[y]]
                xs.setElement[y, temp]
            end swap

            export function getElementOrWrap[i : Integer, xs : ListType] -> [res : itemType]
                res <- xs.getElement[Util.wrapInteger[i, xs.lowerBound, xs.upperBound]]
            end getElementOrWrap
        end NewArrayUtils
    end of
end ArrayUtils
export ArrayUtils

const Pair <- immutable object Pair
    export function of[typeA : Type, typeB : Type] -> [res : NewPairType]
        forall typeA
        forall typeB
        where
            NewPairType <- immutable typeobject NewPairType
                function create[typeA, typeB] -> [NewPair]
            end NewPairType
        where
            NewPair <- immutable typeobject NewPair
                function getFirst -> [typeA]
                function getSecond -> [typeB]
            end NewPair

        res <- immutable object PairCreator
            export function getSignature -> [r : Signature]
                r <- NewPair
            end getSignature

            export function create[x : typeA, y : typeB] -> [res : NewPair]
                res <- immutable object NewPair
                    attached const field first : typeA <- x
                    attached const field second : typeB <- y
                end NewPair
            end create
        end PairCreator
    end of
end Pair
export Pair


const main <- object main
    initially
        const items <- Array.of[String].empty
        items.addUpper["foo"]
        items.addUpper["bar"]
        items.addUpper["baz"]

        const theItem <- ArrayUtils.of[String].pickRandom[items]
        stdout.putstring[theItem || "\n"]
    end initially
end main
