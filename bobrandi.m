function rand_mat = bobrandi(I, m, n)
if length(I) == 1;
  imin = 0;
  imax = I;
else
  imin = I(1);
  imax = I(2);
end;
rand_mat = zeros(m,n);
diff = imax - imin; 

for i = 1:m
  for j = 1:n
      rand_no = ceil(diff*rand);
  rand_mat(i,j) = imin + rand_no;
  end;
end;
return;