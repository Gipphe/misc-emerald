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

const Store <- object Store
    export operation buySoap[ba : BankAccount] -> [r : Integer]
        r <- 0
        loop
            exit when ba$balance < 10
            const unused <- ba.withdraw[10]
            r <- r + 1
        end loop
    end buySoap
end Store

const main <- object main
    initially
        var soapsBought : Integer
        const ba <- BankAccount.create[100]

        % Called 10 times remotely
        soapsBought <- Store.buySoap[ba]

        const bigBA <- BankAccount.create[10000]

        % Called 1000 times remotely
        soapsBought <- Store.buySoap[bigBA]

        % Called 1000 times locally. bigBA remains at Store's node.
        soapsBought <- Store.buySoap[move bigBA]

        % Called 1000 times locally. bigBA is moved back to its starting node.
        soapsBought <- Store.buySoap[visit bigBA]

        % Call-by-visit is equivalent to:
        const home : Node <- locate bigBA
        move bigBA to Store
        soapsBought <- Store.buySoap[bigBA]
        move bigBA to home % Omit to replicate call-by-move.
    end initially
end main
