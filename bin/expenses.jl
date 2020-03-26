#!/usr/bin/env julia
import Pkg
Pkg.activate(joinpath(splitdir(realpath(PROGRAM_FILE))[1],".."))

using Dates
using Printf

import LedgerTools.OrgMode

function main()
    BUDGET=ARGS[1]

    LEDGER=OrgMode.getsheet(BUDGET,"LEDGER")[1,1]

    MONTHS=["JAN","FEB","MAR","APR","MAY","JUN",
            "JUL","AUG","SEP","OCT","NOV","DEC"]
    
    CODE2CATEGORY=Dict("income"=>"*Income*")
    x=OrgMode.getsheet(BUDGET,"CODES")
    for i=1:size(x,1)
        CODE2CATEGORY[x[i,1]]=x[i,2]
    end

    ACCOUNTS=[]
    x=OrgMode.getsheet(BUDGET,"ACCOUNTS")
    for i=1:size(x,1)
        push!(ACCOUNTS,x[i,1])
    end

    cmd=`ledger -f $(LEDGER) csv $(ACCOUNTS) -S date`

    section=Dict()
    
    for x in map(strip,open(readlines,cmd))
        s=split(x,",")
        if length(s)!=8
            error("Problem parsing transaction")
        end
        if s[5][2:end-1]=="\$"
            dt=DateTime(parse(Int,s[1][2:5]),
                        parse(Int,s[1][7:8]),
                        1)
            code=s[2][2:end-1]
            if code=="income"
                dt=dt+Dates.Month(1)
            end
            amount=parse(Float64,s[6][2:end-1])
            if !haskey(CODE2CATEGORY,code)
                CODE2CATEGORY[code]="*Income*"
            end
            category=CODE2CATEGORY[code]
            amt=@sprintf("\$%.2f",-amount)
            if length(amt)<10
                amt=" "^(10-length(amt))*amt
            end
            if !haskey(section,dt)
                section[dt]=Dict()
            end
            if !haskey(section[dt],category)
                section[dt][category]=[]
            end
            push!(section[dt][category],"*** $(s[1]) $(amt) ($(code)) $(s[3])") 
        end
    end

    for dt in sort(collect(keys(section)))
        println("* $(MONTHS[month(dt)])$(year(dt))")
        for category in sort(collect(keys(section[dt])))
            println("** $(category)")
            for transaction in section[dt][category]
                println(transaction)
            end
        end
    end
    
end

main()
