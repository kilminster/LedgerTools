module OrgMode

function getsheetnames(fname)
    r=[]
    for x in map(strip,open(readlines,fname))
        name=match(r"^\#\+NAME:(.*)",x)
        if name!=nothing
            push!(r,strip(name.captures[1]))
        end
    end
    return r
end

function getsheet(fname,name)
    r=[]
    onsheet=false
    for x in map(strip,open(readlines,fname))
        mname=match(r"^\#\+NAME:(.*)",x)
        if mname!=nothing
            if strip(mname.captures[1])==name
                onsheet=true
            else
                onsheet=false
            end
        end
        if onsheet
            if (length(x)==0)||(!(x[1] in "|#"))
                onsheet=false
            end
        end
        if onsheet
            if (length(x)>=2)&&(x[1]=='|')&&(x[2]!='-')
                push!(r,hcat(map(strip,split(x,"|")[2:end-1])...))
            end
        end
    end
    return vcat(r...)
end

function writesheet(fname,name,data)
    onsheet=false
    lines=map(strip,open(readlines,fname))
    row=1
    F=open(fname,"w")
    for x in lines
        mname=match(r"^\#\+NAME:(.*)",x)
        if mname!=nothing
            if strip(mname.captures[1])==name
                onsheet=true
            else
                onsheet=false
            end
        end
        if onsheet
            if (length(x)==0)||(!(x[1] in "|#"))
                onsheet=false
            end
        end        
        if onsheet
            if (length(x)>=2)&&(x[1]=='|')&&(x[2]!='-')
                println(F,"|",join(data[row,1:end],"|"),"|")
                row=row+1
            else
                println(F,x)
            end
        else
            println(F,x)
        end
    end
    close(F)
end


function writesheetformulae(fname,name,formulae)
    onsheet=false
    lines=map(strip,open(readlines,fname))
    row=1
    F=open(fname,"w")
    for x in lines
        mname=match(r"^\#\+NAME:(.*)",x)
        if mname!=nothing
            if strip(mname.captures[1])==name
                onsheet=true
            else
                onsheet=false
            end
        end
        if onsheet
            if (length(x)==0)||(!(x[1] in "|#"))
                onsheet=false
            end
        end
        if onsheet
            if match(r"^\#\+TBLFM:(.*)",x)!=nothing
                println(F,"#+TBLFM: ",formulae)
            else
                println(F,x)
            end
        else
            println(F,x)
        end
    end
    close(F)
end

end
