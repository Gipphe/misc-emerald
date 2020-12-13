const main <- object main
  function stripLast [ i : String ] -> [ o : String ]
    o <- i.getSlice[0, i.length - 1]
  end stripLast

  function readLine -> [ res : String ]
    res <- self.stripLast[stdin.getstring]
  end readLine

  initially
    const home : Node <- locate self
    const all <- home$activenodes
    loop
      const input <- self.readLine
      exit when input = "exit"

      var elem : NodeListElement
      var friend : Node
      for i : Integer <- 0 while i <= all.upperbound by i <- i + 1
        begin
          elem <- all[i]
          friend <- elem$thenode
          friend$stdout.putstring[input || "\n"]
          unavailable
          end unavailable
        end
      end for
    end loop
  end initially
end main
