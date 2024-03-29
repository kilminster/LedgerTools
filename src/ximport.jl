module XImport

export Transaction,parseledgerfile,writeledgerfile,sortcontents

mutable struct Transaction
    id::String
    date::String
    amount::String
    matchinfo::String
    text::Array{String,1}
end

function parseledgerfile(fname)
    ledgercontents=[]
    transactions=Dict{String,Transaction}()

    function cleanupline(x)
        x=rstrip(x)
        if length(x)>0
            if x[1]=='*'
                return x[2:end]
            end
        end
        return x
    end
    
    ls=map(cleanupline,open(readlines,fname))

    function noneleft()
        while length(ls)>0
            if (length(ls[1])>0)&&(ls[1][1]==';')
                popfirst!(ls)
            else
                return false
            end
        end
        return true
    end
    
    @label START
    if noneleft()
        @goto DONE
    end
    l=popfirst!(ls)
    if length(l)>0
        if l[1]=='*'
            l=l[2:end]
        end
        if l[1]==';'
            l=l[2:end]
            @goto START
        end
        if l[1]=='|'
            @goto TRANSACTION
        end
    end
    push!(ledgercontents,l)
    @goto START
    
    @label TRANSACTION
    _,id,date,amount,matchinfo=split(l,'|')
    text=String[]

    @label TRANSACTIONTEXT
    if noneleft()
        @goto TRANSACTIONDONE
    end
    if length(ls[1])>0
        if ls[1][1] in "0123456789"
            push!(text,popfirst!(ls))
            @goto TRANSACTIONTEXT2
        end
        if ls[1][1] in "|"
            @goto TRANSACTIONDONE
        end
    end
    push!(text,popfirst!(ls))
    @goto TRANSACTIONTEXT

    @label TRANSACTIONTEXT2
    if noneleft()
        @goto TRANSACTIONDONE
    end
    if length(ls[1])>0
        if ls[1][1] in "|0123456789"
            @goto TRANSACTIONDONE
        end
    end
    push!(text,popfirst!(ls))
    @goto TRANSACTIONTEXT2
    
    @label TRANSACTIONDONE
    t=Transaction(id,date,amount,matchinfo,text)
    push!(ledgercontents,t)
    transactions[t.id]=t
    @goto START
    
    @label DONE
    return ledgercontents,transactions
end

function sortcontents(contents)

    function sortkey(transaction::Transaction)
        a=""
        for c in transaction.amount
            if c in "-0123456789."
                a=a*c
            end
        end
        return (transaction.date,parse(Float64,a))
    end

    r=[]
    while length(contents)>0
        if contents[1] isa Transaction
            tosort=Transaction[]
            while (length(contents)>0)&&(contents[1] isa Transaction)
                push!(tosort,popfirst!(contents))
            end
            sort!(tosort,by=sortkey)
            for x in tosort
                push!(r,x)
            end
        else
            push!(r,popfirst!(contents))
        end
    end
    return r
end


function writeledgerfile(fname,contents,transactionidstomark)
    function tostring(t::Transaction)
        r="|$(t.id)|$(t.date)|$(t.amount)|$(t.matchinfo)\n"
        if t.id in transactionidstomark
            r="*"*r
        end
        for x in t.text
            r=r*x*"\n"
        end
        return r
    end

    function tostring(s::AbstractString)
        return s*"\n"
    end

    f=open(fname,"w")
    for x in contents
        write(f,tostring(x))
    end
    close(f)
end


end
