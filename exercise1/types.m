const SimpleCollection <- typeobject SimpleCollection
  operation add [ name : String ] -> [ res : Boolean ]
  function contains [ name : String ] -> [ res : Boolean ]
  operation remove [ name : String ] -> [ res : Boolean ]
end SimpleCollection

const set : SimpleCollection <- object set
  export operation add [ name : String ] -> [ res : Boolean ]
    res <- True
  end add

  export function contains [ name : String ] -> [ res : Boolean ]
    res <- True
  end contains

  export operation remove [ name : String ] -> [ res : Boolean ]
    res <- True
  end remove

	export operation foo [ name : String ] -> [ res : Boolean ]
		res <- False
	end foo
end set

const main <- object main
  initially
    stdout.putstring[set.contains["x"].asString || "\n"]
  end initially
end main
