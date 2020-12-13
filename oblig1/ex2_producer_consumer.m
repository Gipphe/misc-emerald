const container <- monitor object container
    var items: Array.of[Integer] <- Array.of[Integer].empty
    const bufferSize: Integer <- 2
    const readyToRead: Condition <- Condition.create
    const readyToWrite: Condition <- Condition.create

    operation lengthOf[xs: Array.of[Integer]] -> [res: Integer]
        res <- xs.upperBound - xs.lowerBound + 1
    end lengthOf

    export operation read -> [res: Integer]
        if items.empty then
            stdout.putstring["Consumer: Waiting to read\n"]
            wait readyToRead
        end if
        res <- items.removeLower
        stdout.putstring["Consumer: Read " || res.asString || "\n"]
        signal readyToWrite
    end read

    export operation write[i: Integer]
        if self.lengthOf[items] >= bufferSize then
            stdout.putstring["Producer: Waiting to write\n"]
            wait readyToWrite
        end if
        items.addUpper[i]
        stdout.putstring["Producer: Wrote " || i.asString || "\n"]
        signal readyToRead
    end write
end container

const hundredMilliSeconds <- Time.create[0, 100000]

const producer <- object producer
    process
        const home : Node <- locate self
        for i: Integer <- 1 while i <= 30 by i <- i + 1
            if i # 3 == 0 then
                stdout.putstring["Producer: Waiting 100ms...\n"]
                home.delay[hundredMilliSeconds]
            end if
            container.write[i]
        end for
    end process
end producer

const consumer <- object consumer
    process
        const home : Node <- locate self
        for i: Integer <- 1 while True by i <- i + 1
            if i # 5 == 0 then
                stdout.putstring["Consumer: Waiting 100ms...\n"]
                home.delay[hundredMilliSeconds]
            end if
            const input <- container.read
        end for
    end process
end consumer
