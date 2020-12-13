const Kilroy <- object Kilroy
  process
    const home <- locate self
    var there :     Node
    var startTime, diff : Time
    var all : NodeList
    var theElem :NodeListElement
    var stuff : Real

    var nodesVisited : Integer <- 0

    home$stdout.PutString["Starting on " || home$name || "\n"]
    all <- home.getActiveNodes
    home$stdout.PutString[(all.upperbound + 1).asString || " nodes active.\n"]
    startTime <- home.getTimeOfDay
    var curr : Node
    there <- home
    for i : Integer <- 1 while i <= all.upperbound by i <- i + 1
      begin
        curr <- there
        there <- all[i]$theNode
        move Kilroy to there
        nodesVisited <- nodesVisited + 1
        there$stdout.PutString["Kilroy was here\n"]
        unavailable
            curr$stdout.putstring["Unavailable: " || there$name || "\n"]
        end unavailable
      end
    end for
    begin
        move Kilroy to home
        curr <- home
        unavailable
            curr$stdout.putstring["Home is unavailable\n"]
        end unavailable
    end
    diff <- curr.getTimeOfDay - startTime
    const timePerNode: Time <- diff / nodesVisited
    const formattedTimePerNode: String <- timePerNode$seconds.asString || " seconds and " || timePerNode$microSeconds.asString || " microseconds"
    if curr == home then
        curr$stdout.PutString["Back home\n"]
    else
        curr$stdout.putString["Couldn't make it home\n"]
    end if
    curr$stdout.putString["Total time: " || diff.asString || "\n"]
    curr$stdout.putString["Time per jump: " || formattedTimePerNode || "\n"]
  end process
end Kilroy
