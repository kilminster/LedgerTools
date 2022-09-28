module XImporters

using ..XImport
using Dates
using SHA
using Printf

function filterpipe(x::String)
    r=Char[]
    for c in x
        if c!='|'
            push!(r,c)
        end
    end
    return String(r)
end

function asb(newtransactions,fname,currency)
    re=r"(\d\d\d\d/\d\d/\d\d),(\d*),(.*),([+|-]?[\d\.]+)"
    for x in open(readlines,fname)
        m=match(re,strip(x))
        if m!=nothing
            amount=m.captures[4]
            if amount[1]=='-'
                amount=amount[2:end]
            else
                amount="-"*amount
            end
            t=Transaction(m.captures[2],
                          m.captures[1],
                          "$(currency)"*amount,
                          filterpipe(m.captures[3]*"-"*m.captures[4]),
                          String[])
            push!(newtransactions,t)
        end
    end
end

function nab(newtransactions,fname,currency)
    removeexcessspaces(x)=join(split(x),' ')
    re=r"(.*?),(.*?),.*?,.*?,(.*?),(.*?),.*?,(.*)"
    for x in open(readlines,fname)[2:end]
        x1=x
        if length(filter(z->z==',',x1))==6
            x1=x1*","
        end
        m=match(re,strip(x1))
        if m!=nothing
            captures=removeexcessspaces.(m.captures)
            dt=Date(captures[1],"d u y")+Year(2000)
            amount=captures[2]
            if amount[1]=='-'
                amount=amount[2:end]
            else
                amount="-"*amount
            end
            id=bytes2hex(sha256(join(captures,'-')))[1:16]
            matchinfo=filterpipe(join(captures[2:end],'-'))
            t=Transaction(@sprintf("%04d%02d%02d",year(dt),month(dt),day(dt))*id,
                          @sprintf("%04d/%02d/%02d",year(dt),month(dt),day(dt)),
                          "$(currency)"*amount,
                          matchinfo,
                          String[])
            push!(newtransactions,t)
        end
    end
end


function ofx(newtransactions,fname,currency)
    s=String(open(read,fname))
    while true
        i=first(something(findfirst("<STMTTRN>",s),0))
        if i==0
            break
        end
        s=s[i+9:end]
        i=first(something(findfirst("</STMTTRN>",s),0))
        s1=s[1:i-1]
        s=s[i:end]
        d=Dict{String,String}()
        for s2 in split(s1,'<')
            s3=map(strip,split(s2,'>'))
            if length(s3)==2
                d[s3[1]]=s3[2]
            end
        end
        amount=d["TRNAMT"]
        if amount[1]=='-'
            amount=amount[2:end]
        else
            amount="-"*amount
        end
        date=d["DTPOSTED"]
        date=date[1:4]*"/"*date[5:6]*"/"*date[7:8]
        t=Transaction(d["FITID"],
                      date,
                      "$(currency)"*amount,
                      filterpipe(join([d[k] for k in sort(collect(keys(d)))],'-')),
                      String[])
        push!(newtransactions,t)
    end
end


end
