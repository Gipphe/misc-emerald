% imports HashTest
% imports Test

const main <- object main
    initially
        const separator : String <- "-----------------"
        const results <- Array.of[Result].empty
        const successes <- Array.of[Result].empty
        const failures <- Array.of[Result].empty

        results.concat[hashTests]

        const numResults <- results.upperBound - results.lowerBound + 1
        stdout.putstring["\n\nRunning " || numResults.asString || " tests...\n\n"]

        for i : Integer <- results.lowerBound while i <= results.upperBound by i <- i + 1
            const theResult : Result <- results.getElement[i]
            stdout.putstring[theResult$message]
            if theResult.isOk then
                stdout.putstring[" - OK\n"]
                successes.addUpper[theResult]
            else
                stdout.putstring[" - FAILURE\n"]
                failures.addUpper[theResult]
            end if
        end for

        if failures.lowerBound > failures.upperBound then
            stdout.putstring["\nAll tests passed!\n"]
        else
            stdout.putstring["\n" || separator || "\n\n"]

            for i : Integer <- failures.lowerBound while i <= failures.upperBound by i <- i + 1
                const theResult <- failures.getElement[i]
                const theInfo <- theResult$testInfo
                stdout.putstring
                    [  theResult$message
                    || "\nExpected: "
                    || theInfo$expected
                    || "\nActual: "
                    || theInfo$actual
                    || "\nWith operation: "
                    || theInfo$comparison
                    || "\n\n"
                    ]
            end for

            const numSuccesses <- successes.upperBound - successes.lowerBound + 1
            const numFailures <- failures.upperBound - failures.lowerBound + 1
            stdout.putstring[separator || "\n\nSuccessful: " || numSuccesses.asString || "\nFailed: " || numFailures.asString || "\n"]
        end if
    end initially
end main
