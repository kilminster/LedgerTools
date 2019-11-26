#!/usr/bin/env julia
import Pkg
Pkg.activate(joinpath(splitdir(realpath(PROGRAM_FILE))[1],".."))

using LedgerTools.XImport
import LedgerTools.XImporters
import LedgerTools.XImportModel

function main()
    ledgerfile=nothing
    currenttransactions=Transaction[]
    currency="\$"
    markcurrenttransactions=false
    
    while length(ARGS)>0
        x=popfirst!(ARGS)
        if x[1]=='-'
            if x=="-asb"
                XImporters.asb(currenttransactions,popfirst!(ARGS),currency)
            elseif x=="-ofx"
                XImporters.ofx(currenttransactions,popfirst!(ARGS),currency)
            elseif x=="-nab"
                XImporters.nab(currenttransactions,popfirst!(ARGS),currency)
            elseif x=="-currency"
                currency=popfirst!(ARGS)
            elseif x=="-mark"
                markcurrenttransactions=true
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

    sort!(currenttransactions,by=t->t.date)

    ledgercontents,transactions=parseledgerfile(ledgerfile)

    for t in currenttransactions
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

    if markcurrenttransactions
        writeledgerfile(ledgerfile,ledgercontents,[t.id for t in currenttransactions])
    else
        writeledgerfile(ledgerfile,ledgercontents,[])
    end
end

main()
