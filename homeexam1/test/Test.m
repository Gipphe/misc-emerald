const Info <- typeobject Info
    function getActual -> [ res : String ]
    function getExpected -> [ res : String ]
    function getComparison -> [ res : String ]
end Info
export Info

const InfoBuilder <- object InfoBuilder
    export function create[ theActual : String, theExpected : String, theComparison : String ] -> [ res : Info ]
        res <- object NewInfo
            const field actual : String <- theActual
            const field expected : String <- theExpected
            const field comparison : String <- theComparison
        end NewInfo
    end create
end InfoBuilder
export InfoBuilder

const Result <- typeobject Result
    function getTestInfo -> [ res : Info ]
    function isOk -> [ res : Boolean ]
    function getMessage -> [ res : String ]
    operation runAssertion
end Result
export Result

const TheTest <- typeobject TheTest
    function getTestInfo -> [ res : Info ]
    operation runTest -> [ res : Boolean ]
end TheTest
export TheTest

const NeedsTest <- typeobject NeedsTest
    operation test[ tc : TheTest ] -> [ res : Result ]
end NeedsTest
export NeedsTest

const NeedsShould <- typeobject NeedsShould
    operation should[ msg : String ] -> [ res : NeedsTest ]
end NeedsShould
export NeedsShould

const NeedsGiven <- typeobject NeedsGiven
    operation given[ msg : String ] -> [ res : NeedsShould ]
end NeedsGiven
export NeedsGiven

const With <- object With
    export operation the [ suite : String ] -> [ res : NeedsGiven ]
        res <- object NewCase
            field shouldMsg : String <- ""
            field givenMsg : String <- ""

            export operation given[ msg : String ] -> [ res : NeedsShould ]
                self.setGivenMsg[msg]
                res <- self
            end given

            export operation should[ msg : String ] -> [ res : NeedsTest ]
                self.setShouldMsg[msg]
                res <- self
            end should

            export operation test[ tc : TheTest ] -> [ res : Result ]
                res <- object NewResult
                    attached const field message : String <- suite || " : given " || givenMsg || ", should " || shouldMsg
                    attached const field ok : Boolean <- tc.runTest
                    attached const field testInfo : Info <- tc$testInfo

                    export function isOk -> [ res : Boolean ]
                        res <- self$ok
                    end isOk

                    export operation runAssertion
                        assert self$ok
                    end runAssertion
                end NewResult
            end test
        end NewCase
    end the
end With
export With
