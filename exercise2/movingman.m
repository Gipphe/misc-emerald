const main <- object main
  function getIdentifier [elem : Node] -> [ o : String ]
    o <- elem$name || " " || elem$incarnationTime.asString
  end getIdentifier

  initially
    var identList : Array.of[String] <- Array.of[String].empty
    var home : Node <- locate self
    const nodes <- home$activenodes
    var elem : NodeListElement
    var identifier : String
    var place : Node

    for i : Integer <- 0 while i <= nodes.upperbound by i <- i + 1
      elem <- nodes[i]
      begin
        move self to elem$thenode
        place <- locate self
        identifier <- self.getIdentifier[place]
        identList.addUpper[identifier]
        place$stdout.putstring[identifier || "\n"]
        unavailable
          identifier <- self.getIdentifier[elem$thenode]
          identList.addUpper[identifier || " - Unavailable"]
        end unavailable
      end
    end for

    begin
      move self to home
      unavailable
        % if home has become unavailable, reassign home to the current node
        home <- locate self
      end unavailable
    end

    for i : Integer <- 0 while i <= identList.upperbound by i <- i + 1
      stdout.putstring[identList[i] || "\n"]
    end for
  end initially
end main
