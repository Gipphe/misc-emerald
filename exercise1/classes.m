const PersonType <- typeobject PersonType
  function getname -> [ res : String ]
end PersonType

const Person <- object Person
  export function create [ name : String ] -> [res : PersonType]
    res <- object PersonImpl
      export function getname -> [ res : String ]
        res <- name
      end getname
    end PersonImpl
  end create
end Person

const main <- object main
  initially
    const oleks <- Person.create["Oleks"]
    stdout.putstring[oleks.getname || "\n"]

    const eric <- Person.create["Eric"]
    stdout.putstring[eric.getname || "\n"]
  end initially
end main
