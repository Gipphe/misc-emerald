const Util <- object Util
    % Excessively simple implementation of an exponentiation function. Does
    % not work for negative exponents, and will only return 1.
    export function power
        [ base : Integer
        , exponent : Integer
        ]
    -> [ res : Integer ]
        res <- 1
        for i : Integer <- 0 while i < exponent by i <- i + 1
            res <- res * base
        end for
    end power

    % Taken from this stack overflow answer:
    % https://stackoverflow.com/a/28332394
    % Specifically the following part:
    % #define XOR(a,b) (a - AND(a,b) +  b - AND(a,b) )
    % Now, I'm no C programmer myself, but if I interpreted that #define
    % correctly, then this is the Emerald equivalent. I must admit: I have no
    % idea how or why this works.
    export function bitXor[a : Integer, b : Integer ] -> [ res : Integer ]
        res <- a - (a & b) + b - (a & b)
    end bitXor
end Util
export Util
