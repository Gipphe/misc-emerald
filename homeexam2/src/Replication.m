%%%%%%%%%%%
% Framework
%%%%%%%%%%%

const State <- immutable object State
    export function of[containerType : Type, itemType : Type] -> [res : Type]
        forall containerType
        forall itemType
        res <- typeobject NewStateType
            function getState -> [containerType]
            operation addToState[itemType]
            operation removeFromState[itemType]
            operation halt
        end NewStateType
    end of
end State
export State

const Replica <- immutable object Replica
    export function of[containerType : Type, itemType : Type] -> [res : NewReplicaType]
        forall itemType
        suchThat containerType *>
            typeobject CloneableState
                operation addToState[itemType]
                operation removeFromState[itemType]
            end CloneableState
        where
            ParentType <- typeobject NewParentType
                operation addToState[itemType]
                operation removeFromState[itemType]
                operation halt
            end NewParentType
        where
            NewReplicaType <- immutable typeobject NewReplicaType
                function create[ParentType, containerType] -> [NewReplica]
            end NewReplicaType
        where
            NewReplica <- typeobject NewReplica
                function getState -> [containerType]
                operation addToState[itemType]
                operation removeFromState[itemType]
                operation addToOwnState[itemType]
                operation removeFromOwnState[itemType]
                operation halt
            end NewReplica

        res <- immutable object ReplicaCreator
            export function getSignature -> [r : Signature]
                r <- NewReplica
            end getSignature

            export function create[theParent : ParentType, initialState : containerType] -> [res : NewReplica]
                res <- object NewReplica
                    attached const state : containerType <- initialState

                    export function getState -> [res : containerType]
                        res <- state
                    end getState

                    export operation addToState[newItem : itemType]
                        theParent.addToState[newItem]
                    end addToState

                    export operation removeFromState[theItem : itemType]
                        theParent.removeFromState[theItem]
                    end removeFromState

                    export operation addToOwnState[theItem : itemType]
                        state.addToState[theItem]
                    end addtoOwnState

                    export operation removeFromOwnState[theItem : itemType]
                        state.removeFromState[theItem]
                    end removeFromOwnState

                    export operation halt
                        theParent.halt
                    end halt
                end NewReplica
            end create
        end ReplicaCreator
    end of
end Replica
export Replica

const Primary <- immutable object Primary
    export function of[containerType : Type, itemType : Type] -> [res : NewPrimaryType]
        forall itemType
        suchThat containerType *>
            typeobject CloneableState
                function cloneMe -> [containerType]
                operation addToState[itemType]
                operation removeFromState[itemType]
            end CloneableState
        where ReplicaType <- Replica.of[containerType, itemType]
        where UpdateEntry <- Pair.of[Boolean, itemType]
        where UpdatesList <- Array.of[UpdateEntry]
        where
            NewPrimaryType <- immutable typeobject NewPrimaryType
                function create[containerType] -> [NewPrimary]
            end NewPrimaryType
        where
            NewPrimary <- typeobject NewPrimary
                function getState -> [containerType]
                operation addToState[itemType]
                operation removeFromState[itemType]
                function replicate -> [ReplicaType]
                operation halt
            end NewPrimary

        res <- immutable object PrimaryCreator
            export function create[initialState : containerType] -> [res : NewPrimary]
                res <- object NewPrimary
                    attached const updatesToPropagate : UpdatesList <- UpdatesList.empty
                    attached const thisState : containerType <- initialState
                    attached field replicas : Array.of[ReplicaType] <- Array.of[ReplicaType].empty
                    attached var doHalt : Boolean <- false

                    process
                        const home <- locate self
                        loop
                            if doHalt then
                                return
                            end if

                            if !updatesToPropagate.empty then
                                const theUpdate <- updatesToPropagate.removeLower
                                for i : Integer <- replicas.lowerBound
                                while i <= replicas.upperBound
                                by i <- i + 1
                                    begin
                                        const theReplica <- replicas.getElement[i]
                                        const isAddType <- theUpdate$first
                                        const theItem <- theUpdate$second
                                        if isAddType then
                                            theReplica.addToOwnState[theItem]
                                        else
                                            theReplica.removeFromOwnState[theItem]
                                        end if
                                        unavailable
                                        end unavailable
                                    end
                                end for
                            end if
                            home.delay[Util.msToTime[1]]
                        end loop
                    end process

                    export operation getState -> [res : containerType]
                        res <- thisState
                    end getState

                    export operation addToState[newItem : itemType]
                        thisState.addToState[newItem]

                        updatesToPropagate.addUpper[UpdateEntry.create[true, newItem]]
                    end addToState

                    export operation removeFromState[theItem : itemType]
                        thisState.removeFromState[theItem]

                        updatestoPropagate.addUpper[UpdateEntry.create[false, theItem]]
                    end removeFromState

                    export function replicate -> [res : ReplicaType]
                        res <- ReplicaType.create[self, thisState.cloneMe]
                        replicas.addUpper[res]
                    end replicate

                    export operation halt
                        doHalt <- true
                    end halt
                end NewPrimary
            end create
        end PrimaryCreator
    end of
end Primary
export Primary

const Replicator <- immutable object Replicator
    export function of[containerType : Type, itemType : Type] -> [res : NewReplicatorType]
        forall itemType
        suchThat containerType *>
            typeobject Cloneable
                function cloneMe -> [containerType]
                operation addToState[itemType]
                operation removeFromState[itemType]
            end Cloneable
        where StateList <- Array.of[State.of[containerType, itemType]]
        where
            NewReplicatorType <- immutable typeobject NewReplicatorType
                function replicate[containerType, Integer] -> [StateList]
            end NewReplicatorType

        res <- immutable object NewReplicator
            export operation replicate[x : containerType, limit : Integer] -> [res : StateList]
                const home : Node <- locate self
                % Usually, Node.getActiveNodes returns a
                % Vector.of[NodeListElement]. Unfortunately, we need it to be
                % an Array instead, so we just catenate an empty array with
                % the Vector.of[NodeListElement] returned by
                % Node.getActiveNodes, and we've got an
                % Array.of[NodeListElement]!
                const nodes <- Array
                    .of[NodeListElement]
                    .empty
                    .catenate[home$activeNodes]
                const prim <- Primary.of[containerType, itemType].create[x]
                res <- StateList.empty
                res.addUpper[prim]

                for i : Integer <- 0
                while i < limit
                by i <- i + 1
                    const theNode <- ArrayUtils
                        .of[NodeListElement]
                        .getElementOrWrap[i, nodes]
                    const theReplica : Replica.of[containerType, itemType] <- prim.replicate
                    move theReplica to theNode$theNode
                    res.addUpper[theReplica]
                end for
            end replicate

            export operation halt[states : StateList]
                if !states.empty then
                    states.getElement[states.lowerBound].halt
                end if
            end halt
        end NewReplicator
    end of
end Replicator
export Replicator


%%%%%%%%%%%
% Utilities
%%%%%%%%%%%

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
