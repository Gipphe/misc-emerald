% imports Hash
% imports Test

const hashTests <- Array.of[Result].empty
export hashTests

const main <- object main
    function testString[theValue : String, theExpected : Integer] -> [ res : Result ]
        const theActual : Integer <- DjbHash.hash[theValue]

        res <- With.the["DjbHash.hash"]
            .given["the string \"" || theValue || "\""]
            .should["return " || theExpected.asString]
            .test[object NewTest
                const field testInfo : Info <- InfoBuilder.create[theActual.asString, theExpected.asString, "=="]
                export function runTest -> [ res : Boolean ]
                    res <- theActual == theExpected
                end runTest
            end NewTest]
    end testString

    initially
        hashTests.addUpper[self.testString["foo", 193410979]]
        hashTests.addUpper[self.testString["bar", 193415156]]
        hashTests.addUpper[self.testString["foobar", 1353372818]]
        hashTests.addUpper[self.testString["A bit of a longer string, but still rather manageable", 3791462889]]
    end initially
end main
