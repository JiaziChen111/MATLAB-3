function f = MichaelCurran(S,CP,K,alp,Spg,df,r,b,sig,ti,t,T)

% -------------------------------------------------------------------------
% f = MichaelCurran(CP,S,K,alp,Spg,df,r,b,sig,ti,t,T)
%
% Author: Michael Shou-Cheng Lee.
%
% This function calculates the price of a fixed-strike
% Asian option with equal time fixings using arithmetic average
% Michael Curran's Model.
%
% CP =  'c' if it is a call; 'p' if it is a put.
% S =   the current asset price.
% K =   the strike price.
% alp = the array of normalised weights.
% Spg = the array of observed fixings.
% df = the discount factor.
% r =   the array of risk-free rates.
% b =   the array of cost of carries.
% sig = the array of volaitlities.
% ti =  array of time to the ith fixing from
%       contract origination date.
% t =   the current time measured from contract origination date.
% T =   the original time to maturity.
% -------------------------------------------------------------------------

if (CP ~= 'c' && CP ~= 'p')
    fprintf('Call/Put CP must be ''c'' or ''p''.\n');
    return;
end

if (length(alp)~=length(r) || length(alp)~=length(b) || length(alp)~=length(sig) || length(alp)~=length(ti))
    fprintf('Array of inputs do not match.\n');
    return;
end

if(t>ti(1))
    if (length(Spg) == length(find(ti<=t)))
        Spg = Spg;
    else
        fprintf('Number of observed fixings mismatch the current time.\n');
        return;
    end

elseif (t==ti(1))
    if(length(Spg)==length(S) && Spg==S)
        Spg = S;
    else
        fprintf('When t==t1, we can only have the current observation.\n');
        return;
    end
else
    if (length(Spg) == 0)
        Spg = [];
    else
        fprintf('When t<t1, we cannot have any oberserved fixings.\n');
        return;
    end
end

if (ti(length(ti)) > T)
    fprintf('Fixings after option expiration is not permitted.\n');
    return;
end

if (t > T)
    fprintf('Valuation date after option exipiration is not permitted.\n');
    return;
end

if(length(Spg)~=0)
    if (t==ti(length(Spg)) && S~=Spg(length(Spg)))
        fprintf('Current asset price does not match the observed fixing.\n');
        return;
    end
end

nf = length(alp);
no = length(Spg);

r = r(:);
W = sum(alp);

Wf = 0;
for i=no+1:nf
    Wf = Wf + alp(i);
end

Wf;

m = 0;
for i=1:nf
    m(i) = log(S)+b(i)*(ti(i)-t)-1/2*sig(i)^2*(ti(i)-t);
end
m = m(:);

rho=0;
for i=1:nf
    for j=i:nf
        if(i==j)
            rho(i,j) = 1;
        else
            rho(i,j) = sqrt(sig(i)^2*(ti(i)-t)/(sig(j)^2*(ti(j)-t)));
            rho(j,i) = rho(i,j);
        end
    end
end

if (ti(1)<t)
    msum = 0;
    for i=no+1:nf
        msum = msum + alp(i)*m(i);
    end
    msum = 1/Wf*msum;

    Sbar = 0;
    for i=1:no
        Sbar = Sbar + alp(i)*Spg(i);
    end
    
    Sbar;
    Kbar = W/Wf*K - 1/Wf*Sbar;

    sigA2 = 0;
    for i=no+1:nf
        for j=no+1:nf
            sigA2 = sigA2 + alp(i)*alp(j)*sig(i)*sqrt(ti(i)-t)*sig(j)*sqrt(ti(j)-t)*rho(i,j);
        end
    end
    sigA2 = 1/Wf^2*sigA2;
    sigA = sqrt(sigA2);
    
    bigsum = 0;
    innersum = 0;
    for i=no+1:nf
        for j=no+1:nf
            innersum = innersum + alp(j)*rho(i,j)*sig(j)*sqrt(ti(j)-t);
        end
        bigsum = bigsum + 1/Wf*(alp(i)*exp(m(i)+1/2*sig(i)^2*(ti(i)-t)))* ...
            normcdf((msum-log(Kbar))/sigA+(sig(i)*sqrt(ti(i)-t)/Wf)*innersum/sigA);
        
        innersum = 0;
    end
    
    callprice = df*Wf/W*(bigsum-Kbar*normcdf((msum-log(Kbar))/sigA));

    smallsum = 0;
    for i=1:nf
        smallsum = smallsum + alp(i)*exp(b(i)*(ti(i)-t));
    end

    putprice = callprice + df*(K-1/W*smallsum);

    if (CP=='c')
        f = callprice;
    else
        f = putprice;
    end

else

    msum = 1/W*alp'*m;

    sigA2 = 0;
    for i=1:nf
        for j=1:nf
            sigA2 = sigA2 + alp(i)*alp(j)*sig(i)*sqrt(ti(i)-t)*sig(j)*sqrt(ti(j)-t)*rho(i,j);
        end
    end
    sigA2 = 1/W^2*sigA2;

    sigA = sqrt(sigA2);

    bigsum = 0;
    innersum = 0;
    for i=1:nf
        for j=1:nf
            innersum = innersum + alp(j)*rho(i,j)*sig(j)*sqrt(ti(j)-t);
        end
        bigsum = bigsum + 1/W*(alp(i)*exp(m(i)+1/2*sig(i)^2*(ti(i)-t)))* ...
            normcdf((msum-log(K))/sigA+(sig(i)*sqrt(ti(i)-t)/W)*innersum/sigA);
        
        innersum = 0;
    end
    
    bigsum = bigsum*1/W;
    
    callprice = df*(bigsum-K*normcdf((msum-log(K))/sigA));

    smallsum = 0;
    for i=1:nf
        smallsum = smallsum + alp(i)*exp(b(i)*(ti(i)-t));
    end

    putprice = callprice + df*(K-1/W*smallsum);

    if (CP=='c')
        f = callprice;
    else
        f = putprice;
    end

end

end
