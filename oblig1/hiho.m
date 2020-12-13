% Tests process creation, monitors, conditions and process switching.

const initialObject <- object initialObject
  process
    const newobj <- object innerObject
      const monobj <- monitor object MonitorObject
        var flip : Integer <- 0
        const c : Condition <- Condition.create

        export operation Hum
        end Hum

        export operation Hi
          if flip = 0 then
            wait c
          end if
          stdout.putstring["hi\n"]
          flip <- 0
          signal c
        end hi
        export operation Ho
          if flip != 0 then
            wait c
          end if
          stdout.putstring["ho\n"]
          flip <- 1
          signal c
        end ho
      end MonitorObject
      export operation Hi
        monobj.hi
      end Hi
      process
        loop
          monobj.ho
        end loop
      end process
    end innerObject

    loop
      newobj.hi
    end loop
  end process
end initialObject
