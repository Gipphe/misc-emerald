const MonitorType <- typeobject MonitorType
    operation enter[p: Integer]
    operation leave[p: Integer]
end MonitorType

const MonitorCreator <- object monitorCreator
    export function create[maxProcesses : Integer] -> [res : MonitorType]
        res <- monitor object MonitorObject
            var waitingByTheBarrier : Integer <- 0
            const barrierDown : Condition <- Condition.create

            export operation enter[p: Integer]
                waitingByTheBarrier <- waitingByTheBarrier + 1
                if waitingByTheBarrier < maxProcesses then
                    stdout.putstring[p.asString || ": Waiting\n"]
                    wait barrierDown
                else
                    stdout.putstring[p.asString || ": Opening\n"]
                    signal barrierDown
                end if
                waitingByTheBarrier <- waitingByTheBarrier - 1
                stdout.putstring[p.asString || ": Entering\n"]
            end enter
            export operation leave[p: Integer]
                stdout.putstring[p.asString || ": Leaving\n"]
            end leave
        end MonitorObject
    end create
end monitorCreator

const BarrierWalker <- object BarrierWalker
    export operation walkTheBarrier[p: Integer, monitorObj: MonitorType]
        monitorObj.enter[p]
        monitorObj.leave[p]
    end walkTheBarrier
end BarrierWalker

const InfiniteRunner <- object InfiniteRunner
    export operation create[p: Integer, monitorObj: MonitorType]
        object Runner
            process
                loop
                    BarrierWalker.walkTheBarrier[p, monitorObj]
                end loop
            end process
        end Runner
    end create
end InfiniteRunner

const LimitedRunner <- object LimitedRunner
    export operation create[p: Integer, monitorObj: MonitorType]
        object LimitedRunner
            process
                for i: Integer <- 0 while i < 3 by i <- i + 1
                    BarrierWalker.walkTheBarrier[p, monitorObj]
                end for
                stdout.putstring[p.asString || ": Finished walking the barrier\n"]
            end process
        end LimitedRunner
    end create
end LimitedRunner

const main <- object main
    initially
        const p : Integer <- 5
        const monitorObj <- MonitorCreator.create[p]
        for i: Integer <- 0 while i < p - 1 by i <- i + 1
            InfiniteRunner.create[i, monitorObj]
        end for
        LimitedRunner.create[p, monitorObj]
    end initially
end main
