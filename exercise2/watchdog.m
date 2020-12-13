const main <- object main
  function getIdentifier [elem : Node] -> [ o : String ]
    o <- elem$name || " " || elem$incarnationTime.asString
  end getIdentifier

  initially
    const home : Node <- locate self
    const elems : NodeList <- home$activenodes
    const states : Array.of[Array.of[String]] <- Array.of[Array.of[String]].create[elems.upperbound]

    var curr : Array.of[String]
    for i : Integer <- 0 while i <= elems.upperbound by i <- i + 1
      curr <- Array.of[String].create[2]
      elem <-
      curr.setElement[0, ]
      states.addUpper[]
    end for
    var elem : NodeListElement
    var ident : String
    loop
      for i : Integer <- 0 while i <= nodes.upperbound by i <- i + 1
        elem <- nodes[i]
        if elem$up then
          ident <- self.getIdentifier[elem$thenode]
          ups.addUpper[ident]
        else
          downs.addUpper[ident]
        end if
      end for

      stdout.putstring["Available nodes:\n"]
      for i : Integer <- 0 while i <= ups.upperbound by i <- i + 1
        stdout.putstring[ups[i] || "\n"]
      end for

      stdout.putstring["\nUnavailable nodes:\n"]
      for i : Integer <- 0 while i <= downs.upperbound by i <- i + 1
        stdout.putstring[downs[i] || "\n"]
      end for

      home.delay[Time.create[1,0]]
    end loop
  end initially
end main
