module XImportModel

using ..XImport
using StringDistances

function build(transactions)
    r=Transaction[]
    for t in transactions
        if length(t.text)>0
            push!(r,t)
        end
    end
    return r
end

function guess(model,t)
    if length(model)==0
        return
    end
    bestm=model[1]
    best=1000000
    for m in model
        c=evaluate(Levenshtein(),m.matchinfo,t.matchinfo)
        if c<best
            best=c
            bestm=m
        end
    end
    for x in bestm.text
        push!(t.text,";"*x)
    end
    if length(t.text)>1
        if t.text[1][2] in "0123456789"
            while (length(t.text[1])>0)&&(t.text[1][1]!=' ')
                t.text[1]=t.text[1][2:end]
            end
            t.text[1]=";"*t.date*t.text[1]
            spacecount=0
            while spacecount<2
                if length(t.text[2])==0
                    break
                end
                if t.text[2][end]==' '
                    spacecount=spacecount+1
                else
                    spacecount=0
                end
                t.text[2]=t.text[2][1:end-1]
            end
            t.text[2]=t.text[2]*"  "*t.amount
        end
    end
end

end
