const BankAccount <- immutable object BankAccount
    const BankAccountType <- typeobject BankAccountType
        operation deposit[Integer]
        operation withdraw[Integer] -> [Integer]
        function getBalance -> [Integer]
    end BankAccountType
    export function getSignature -> [r : Signature]
        r <- BankAccountType
    end getSignature
    export function create[initialBalance : Integer] -> [r : BankAccount]
        r <- object NewBankAccount
            field balance : Integer <- initialBalance
            export operation deposit[amount : Integer]
                balance <- balance + amount
            end deposit
            export operation withdraw[amount : Integer] -> [newBalance : Integer]
                balance <- balance - amount
                newBalance <- balance
            end withdraw
        end NewBankAccount
    end create
end BankAccount

const DepositOnlyBA <- typeobject DepositOnlyBA
    operation deposit[Integer]
    function getBalance -> [Integer]
end DepositOnlyBA

const main <- object main
    initially
        const ba : BankAccount <- BankAccount.create[0]
        const doBA : DepositOnlyBA <- restrict ba to DepositOnlyBA
        doBA.deposit[100]
        % const x <- doBA.widthdraw[100]
        % "Main.m", line 34: Operation widthdraw[1] is not defined

        var anyBA : Any <- ba
        var theBA : BankAccount
        if anyBA *> BankAccount then
            theBA <- view anyBA as BankAccount
            const x <- theBA.withdraw[50]
            anyBA <- view theBA as Any
            anyBA <- theBA
        end if
    end initially
end main
