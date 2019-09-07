#!/usr/bin/env julia
import Pkg
Pkg.activate(joinpath(splitdir(realpath(PROGRAM_FILE))[1],".."))

using Dates
using Printf

import LedgerTools.OrgMode

moneystring(x)=@sprintf("%.2f",x)

function main()
    BUDGET=ARGS[1]

    LEDGER=OrgMode.getsheet(BUDGET,"LEDGER")[1,1]

    MONTHS=["JAN","FEB","MAR","APR","MAY","JUN",
            "JUL","AUG","SEP","OCT","NOV","DEC"]

    SHEETS=[]
    for x in OrgMode.getsheetnames(BUDGET)
        if length(x)==7
            m=0
            for i=1:12
                if MONTHS[i]==x[1:3]
                    m=i
                end
            end
            y=try
                parse(Int,x[4:7])
            catch
                0
            end
            if (m!=0)&&(y!=0)
                dt=DateTime(y,m,1)
                push!(SHEETS,(dt,x))
            end
        end
    end
    sort!(SHEETS)

    for i=1:length(SHEETS)
        f="\$6=\$3+\$4-\$5::@2\$4=-vsum(@3\$4..@>\$4)"
        if i>1
            n=size(OrgMode.getsheet(BUDGET,SHEETS[i][2]),1)
            for j=2:n
                f=f*"::@$(j)\$3=remote($(SHEETS[i-1][2]),@$(j)\$6)"
            end
        end
        OrgMode.writesheetformulae(BUDGET,SHEETS[i][2],f)
    end

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

    openingamount=0.0
    outflows=Dict()

    for x in map(strip,open(readlines,cmd))
        s=split(x,",")

        if s[5][2:end-1]=="\$"
            dt=DateTime(parse(Int,s[1][2:5]),
                        parse(Int,s[1][7:8]),
                        1)
            code=s[2][2:end-1]
            if code=="income"
                dt=dt+Dates.Month(1)
            end
            amount=parse(Float64,s[6][2:end-1])
            if dt<SHEETS[1][1]
                openingamount=openingamount+amount
            else
                if !haskey(CODE2CATEGORY,code)
                    println("Warning, don't know what category to use for code: $code")
                    println("Transaction: $x")
                    CODE2CATEGORY[code]="*Income*"
                end
                category=CODE2CATEGORY[code]
                if !haskey(outflows,dt)
                    outflows[dt]=Dict()
                end
                if !haskey(outflows[dt],category)
                    outflows[dt][category]=0.0
                end
                outflows[dt][category]-=amount
            end
        end
    end
    
    for i=1:length(SHEETS)
        dt=SHEETS[i][1]
        x=OrgMode.getsheet(BUDGET,SHEETS[i][2])
        if i==1
            x[2,3]=moneystring(openingamount)
        end
        for j=2:size(x,1)
            if haskey(outflows,dt)&&haskey(outflows[dt],x[j,2])
                x[j,5]=moneystring(outflows[dt][x[j,2]])
            else
                x[j,5]=""
            end
        end
        OrgMode.writesheet(BUDGET,SHEETS[i][2],x)
    end

end

main()
