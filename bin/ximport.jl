#!/usr/bin/env julia
import Pkg
Pkg.activate(joinpath(splitdir(realpath(PROGRAM_FILE))[1],".."))

using LedgerTools.XImport
import LedgerTools.XImporters
import LedgerTools.XImportModel

function main()
    ledgerfile=nothing
    newtransactions=Transaction[]

    while length(ARGS)>0
        x=popfirst!(ARGS)
        if x[1]=='-'
            if x=="-asb"
                XImporters.asb(newtransactions,popfirst!(ARGS))
            elseif x=="-ofx"
                XImporters.ofx(newtransactions,popfirst!(ARGS))
            elseif x=="-nab"
                XImporters.nab(newtransactions,popfirst!(ARGS))
            else
                error("Unknown option: ",x)
            end
        else
            if ledgerfile==nothing
                ledgerfile=x
            else
                error("Can't operate on more than one ledger file.")
            end
        end
    end

    sort!(newtransactions,by=t->t.date)

    ledgercontents,transactions=parseledgerfile(ledgerfile)

    for t in newtransactions
        if !haskey(transactions,t.id)
            push!(ledgercontents,t)
            transactions[t.id]=t
        end
    end

    model=XImportModel.build(values(transactions))

    for t in values(transactions)
        if length(t.text)==0
            XImportModel.guess(model,t)
        end
    end

    writeledgerfile(ledgerfile,ledgercontents)
end

main()
