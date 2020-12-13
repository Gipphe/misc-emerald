const PersonType <- typeobject PersonType
  function getname -> [ res : String ]
end PersonType
const TeacherType <- typeobject TeacherType
  function getname -> [ res : String ]
  function getposition -> [ res : String ]
end TeacherType

const Person <- object PersonMaker
  export function create[name: String ] -> [ res : PersonType ]
    res <- object Person
      export function getname -> [ res : String]
        res <- name
      end getname
    end Person
  end create
end PersonMaker

const Teacher <- object TeacherMaker
  export function create[name: String, position: String] -> [res: TeacherType]
    res <- object Teacher
      export function getname -> [res : String]
        res <- name
      end getname

      export function getposition -> [res: String]
        res <- position
      end getposition
    end Teacher
  end create
end TeacherMaker

const main <- object main
  initially
    const oleks <- Person.create["Oleks"]
    stdout.putstring[oleks.getname || "\n"]

    const eric <- Teacher.create["Eric", "Professor"]
    stdout.putstring[eric.getname || "\n"]
    stdout.putstring[eric.getposition || "\n"]
  end initially
end main
