function M = sqsh_n_sprd (n, A_init, BR, BM, BL, fig_no)
 
% M = sqsh_n_sprd(20, 1, .1, .75, .1, 2);
% M = sqsh_n_sprd(20, 1, .15, .65, .15, 1);
% M = sqsh_n_sprd(20, 2, .15, .65, .15, 2);
% The parameters are:
% how much spread: 20 = 20 columns to the right and to the left of the
% central column
% fraction of activation spreadng from col i-1 to i between time step t and
% t+1;
% fraction of activation remaining in col from time step t to t+1
% (activation decay parameter)
% fraction of activation spreading from col i+1 to i between time step t
% and t+1
% fig_no: optional param. for figure no. of main activation evolution graph
% (default 1).

global T;
 global MaxAct
 
  T = 1;
  MaxAct = 2;
  
  if nargin < 6 
    fig_no = 1;
  end;
    
  
  no_of_cols = 2*n-1;
  no_of_rows = n;

  W = 3;   % width of sliding window;
  no_of_border_cols = W-1;
  B = [BR, BM, BL]';  % weight col vec for activity transfer
  
  M_width = 2*no_of_border_cols + no_of_cols;
  M = zeros(n+1, M_width);
  M(1,no_of_border_cols+n) = A_init; 
  sigma_vec = [];
  max_vec = [];
  diff_vec = [];
  
  %Here we calculate row by row how the activation spreads.  We end up with
  %a matrix M that gives the evolution from a single spike of height A_init
  %to a very flat Gaussian
  for r = 1:no_of_rows
    temp_row = zeros(1, M_width);
    for c = 1:no_of_cols+no_of_border_cols;
      Mwin = M(r,c:c+W-1);
      new_Mcell = Mwin*B;
      if new_Mcell > A_init
        new_Mcell = A_init;
      end;
      temp_row(c + floor(W/2)) = new_Mcell;
    end;
    M(r+1,:) = temp_row;
    X = 1:length(temp_row);
    max_vec(r) = max(temp_row);
     sigma_vec(r) = sqrt(sum(((X-mean(X)).^2).*temp_row)/length(temp_row));
%     sigma_vec(r) = sum(abs(X-mean(X)).*temp_row)/length(temp_row);
     diff_vec(r) = log(max_vec(r))/log(sigma_vec(r));
%     diff_vec(r) = 1/abs(log(sigma_vec(r)));
%         diff_vec(r) = sigma_vec(r);

  end;
  
 % This is the activation evolution graphics
 cols = size(M,2);
 figure(fig_no);
 for i=1:n+1
   if mod(i, 2) == 1;
      subplot(1,ceil(n/2)+1,ceil(i/2)); 
      bar(1:cols, M(i,:), 'k'); axis([0, cols, 0 MaxAct]);
      text(2, 1.9, strcat('Max: ', num2str(round(100*max(M(i,:)))/100)), 'FontSize', 8);
      if i > 1
        text(2, 1.7, strcat('diff: ', num2str(round(100*diff_vec(i-1))/100)), 'FontSize', 8);
      end;
      pause(0.05);
   end;
 end;
  
 % evolution of the sigma.  Each graph is normalized to a Gaussian with a
 % peak height of 1.  The graph is polyfit with a linear fcn and the
 % residual calculated.
 figure(10*fig_no);
 clf(10*fig_no);
 hold on;
 plot(1:length(diff_vec), diff_vec);
 [P,S] = polyfit(1:length(diff_vec), diff_vec, 1);
 X = 1:length(diff_vec);
 plot(X, P(1)*X+P(2) , 'r--');
 residuals = round(1000*S.normr)/1000;
 text(1,max(diff_vec), strcat('Residual: ', num2str(residuals)));
 new_text = strcat('Params:', num2str(n), ', ', ...
                                num2str(A_init), ', ', ...
                                num2str(BR), ', ', ...
                                num2str(BM), ', ', ...
                                num2str(BL));
 text(1,0.9*max(diff_vec), new_text);
 hold off;

% here we "back up" any given activation profile to its original activation
% value.  You start *from the edges* and calculate backwards and upwards, each time
% replacing the values in row n-1 with the ones calculated from below.  
% % figure(20);
% % plot_no = 1;
% % subplot(1,ceil(n/2)+1,plot_no);
% % bar(1:cols, M(n+1,:), 'r', 'EdgeColor', 'None'); axis([0, cols, 0 MaxAct]);
% % plot_no = plot_no + 1;
% % 
% % for row = n+1:-1:2
% %   cur_row = M(row,:);
% %   back_row = zeros(1, cols);
% %   back_row(cols-2) = (1/BR)*cur_row(cols-1);
% %   for c = M_width-3:-1:ceil(M_width/2)
% %     back_row(c) =  1/BR*(cur_row(c+1) ...
% %       - BL*back_row(c+2) ...
% %       - BM*back_row(c+1)); 
% %     c_rev = M_width-c+1;
% %     back_row(c_rev) = back_row(c);
% %   end;
% % 
% %   if mod(row, 2) == 0;
% %     subplot(1,ceil(n/2)+1,plot_no); 
% %     bar(1:cols, back_row, 'r', 'EdgeColor', 'None'); axis([0,cols, 0, MaxAct]);
% %     plot_no = plot_no + 1;
% %   end;
% % 
% % % if you want to see the activation being "backed up"
% % %  bar(1:cols, back_row, 'r'); axis([0,cols, 0, MaxAct]);
% % %  pause(0.25);
% % end;
return;

  