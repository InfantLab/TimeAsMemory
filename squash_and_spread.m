function [X, Y, no_of_timesteps, Stddev] = squash_and_spread (spread_factor, leakage_factor, self_excitation, showgraphics, output_All_Y)

%[X,Y,no_of_timesteps, Stddev] = squash_and_spread(0.0047215, 0.0105, 0.001);

if nargin < 4, showgraphics = true; end
if nargin < 5, output_All_Y = false; end 
    
X = [-1:0.05:1];
XX = [-1:0.005:1];

no_of_cols = length(X);

% I used sigma = 0.01 to get a nice, tight spike at the beginning.
amp = 20;
mu = 0;
sigma = 0.01;                  %0.05; %0.01
no_of_timesteps = 1000;

%% This is the series of gaussians as they should occur
% hold on;
%
% for n = 1:30
%     Y = gaussian(X, amp, mu, sigma);
%     plot(X,Y);
%     drawnow;
%     pause;
%     plot(X,Y, 'w');
%     amp = .9*amp;
%     sigma = 1.10*sigma;
% end;
% hold off;

Stddev = zeros(1, no_of_timesteps);

Y = gaussian(X, amp, mu, sigma);
Y_all = [Y];
X_orig = X;
Y_orig = Y;

%% this is the series of curves produced by spreading activation and
%% activation leakage.
% figure(1);
% clf(1);
% hold on;

% for n = 1:no_of_timesteps
%       if mod(n, 100) == 1 || n == no_of_timesteps
% %     if n == 1 || n == no_of_timesteps
%         % plot(X,Y);
%         area(X,Y);
%         colormap([1,0,0]);
%         axis([min(X), max(X), 0, amp]);
%         axis manual;
%         drawnow;
%         pause(1);
% %         if n ~= no_of_timesteps
% %             plot(X,Y, 'w');
% %             plot(X_orig, Y_orig);
% %         end;
%         if n ~= no_of_timesteps
%              clf(1);
%              plot(X_orig, Y_orig);
% %             drawnow;
%         end;
%
%     end;
%     if n == 1
%         text(-0.6, 5, 'spreading activation');
%     end;

for n = 1:no_of_timesteps
  L = length(Y);
  delta_mat = sparse(1:no_of_cols, 1:no_of_cols, 0);

  % below we calculate the effect of each column on its 2 nhbrs and add
  % all of these changes together to calculate the overall effect on each
  % timestep.

  for pt = 2:L-1
    delta_mat(pt,[pt-1,pt,pt+1]) = ...
      [spread_factor*Y(pt), self_excitation*Y(pt), spread_factor*Y(pt)];
  end;
  %     for pt = 3:L-2
  %         delta_mat(pt,[pt-2,pt-1,pt,pt+1,pt+2]) = ...
  %             [(spread_factor^2)*Y(pt), spread_factor*Y(pt), ...
  %              self_excitation*Y(pt), ...
  %              spread_factor*Y(pt), (spread_factor^2)*Y(pt)];
  %     end;

  delta_vec = sum(delta_mat);
  Y = Y + delta_vec;

  %     Y = (1-leakage_factor)*Y;
  Y = (1-leakage_factor)*(Y.^0.99955);
  Y_all = [Y_all; Y];
  pX = Y/sum(Y);
  std = sqrt(sum(((X-mu).^2).*pX));
  Stddev(n) = std;
end;


if showgraphics
    %graphics
    figure(1);
    for t = 1:no_of_timesteps
      if t<100
        clf(1);
        %   text(-0.6, 5, 'spreading activation');
        Y = Y_all(t, :);
        YY = spline(X,Y,XX);
        area(XX,YY);
        %area(X,Y);
        colormap([1,0,0]);
        axis([min(X), max(X), 0, amp]);
        axis manual;
        drawnow;
        if t == 1
          pause;
        end;
      elseif t<1000 && mod(t,3) == 0
        clf(1);
        plot(X_orig, Y_orig);
        %   text(-0.6, 5, 'spreading activation');
        Y = Y_all(t, :);
        YY = spline(X,Y,XX);
        area(XX,YY);
      %  area(X,Y);
        colormap([1,0,0]);
        axis([min(X), max(X), 0, amp]);
        axis manual;
        drawnow;
      else
        if mod(t, 20) == 0
          clf(1);
          plot(X_orig, Y_orig);
          Y = Y_all(t, :);
          YY = spline(X,Y,XX);
          area(XX,YY);
    %      area(X,Y);
          colormap([1,0,0]);
          axis([min(X), max(X), 0, amp]);
          axis manual;
          drawnow;
        end;
      end;
    %   Activation_mov(t) = getframe;
    end;
    hold on
    YY_orig = spline(X_orig, Y_orig, XX);
    plot(XX, YY_orig);
    %plot(X_orig, Y_orig);
    text(0.2, 18, 'Original activation');
    text(0.4, 1, 'Final activation');
    %Activation_mov(t+1) = getframe;
    hold off;

    % mpgwrite(Activation_mov, colormap, 'Activation_movie.mpg');

    figure(2);
    % start_no = ceil(no_of_timesteps/10);
    start_no = 1;
    %start_no = 1;
    plot(start_no:no_of_timesteps, Stddev(start_no:no_of_timesteps));
    axis([start_no, no_of_timesteps, min(Stddev), max(Stddev)+0.05]);
    text(ceil(no_of_timesteps/3), (max(Stddev) - min(Stddev))/2, 'evolving std. dev.');

    [P,S,MU] = polyfit(start_no:no_of_timesteps, Stddev, 1);
    fprintf('\n Normed residual: %f  \n', S.normr);

end
if output_All_Y
    Y = Y_all;
end
return;

%>>>>>>>>>>>>>>>>>>
% auxiliary functions
%>>>>>>>>>>>>>>>>>>

function y = gaussian (x, amplitude, mu, sigma)

z1 = (x-mu)/sigma;
% y = amplitude.*exp(-(z1.^2)/2);
y = amplitude.*exp(-(z1.^2));

return;