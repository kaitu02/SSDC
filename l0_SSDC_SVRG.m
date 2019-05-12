function [Obj,it]=l0_SSDC_SVRG(X, y, lss, lambda, dlta, eta0, gamma, mu, K, T0, w0, idx, dense)

[d,n]=size(X)
if isempty(idx)
   idx=randsample(n, m0*2^(S+1), true);
end
if isempty(w0)
    w0=zeros(1,d);
end

eps0=g_obj(X,y,lss,w0,dlta) + lambda*nnz(w0);
disp(sprintf('epoch=%d, obj=%.15f', 0, eps0));
count=1;
Obj=[];
it=[];
T = 0;
Time = 0;
Tcpu = 0;
Tgrad = 0;
eta = eta0;

if T0 >= 1
   t = T0; % practical 
else
   t = ceil(10/(gamma*eta)); % theoretical
end



row = 1

for k = 1:K    
    if k > 2
        S = ceil(log2(k));
    else
        S = 1;
    end
    ws = w0;
    vs = (gamma+mu).*ws;    
for s = 1:S  
    st1 = tic;
    st2 = cputime;    
    w = w0;
    avgw = zeros(1,d);
    v = g_gradfull(X,y,w0,lss,dlta);
    for tau = 1:t
        i=idx(count);
    	count=count+1; 
        x = X(:,i);
        %(1)compute \nabla f_{i_k}(w0)
        [g1,ind] = g_grad(x,y(i),w0,lss,dlta);
        %(2)compute \nabla f_{i_k}(w_{tau-1})
        [g2,ind] = g_grad(x,y(i),w,lss,dlta);
        %(3)compute v_k
	g = v + mu*w;
        g(ind) = g(ind) + g2-g1;
        w = (w./eta + vs - g)./(gamma + 1/eta);
        w(abs(w)<=sqrt(2*lambda/(gamma+1/eta))) = 0; % l0 mapping: hard-thresholding
	    avgw = avgw + w;
    end
    
    Tcpu = Tcpu + (cputime-st2);
    it(row,1) = Tcpu; % cpu time
    Time = Time + toc(st1);
    it(row,2) = Time; % running time
    T = T + t;
    it(row,3) = T; % iteraction 
    Tgrad = Tgrad + (t+n);
    it(row,4) = Tgrad; % # of computing gradient 
	w0 = avgw./t;     
    Obj(row)= g_obj(X,y,lss,w0,dlta) + lambda*nnz(w0);
    row = row + 1;
end
       disp(sprintf('stage=%d, epoch=%d, obj=%.25f, cpu=%d,time=%d,T=%d, Tgrad=%d', ...
        k, row-1, Obj(row-1),ceil(Tcpu),Time,T,Tgrad));
end

it = [0,0,0,0; it];
Obj = [eps0, Obj];
