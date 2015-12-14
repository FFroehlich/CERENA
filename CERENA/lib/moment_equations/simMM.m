% function [X,Y,XRed,SX,SY] = simMM(t,theta,x0) 
function varargout = simMM(varargin) 

t = varargin{1};
theta = varargin{2};
x0 = [];
if nargin>2
    x0 = varargin{3};
end
data.theta = theta;
% Set solver options 
options_CVode = CVodeSetOptions('RelTol',1e-6,...
                                'AbsTol',1e-6,...
                                'MaxNumSteps',10^6,...
                                'JacobianFn',@jacfn,...
                                'Userdata',data);
options_CVodes = CVodeSensSetOptions('method','Simultaneous',...
                                     'ErrControl',true,...
                                     'ParamScales',1:length(theta));

% Initial conditions
if isempty(x0)
    x0 = x0fun(theta);
end
if nargout >= 4
    sx0 = sx0fun(theta);
end

% Initialization of CVode
CVodeInit(@rhs,'BDF','Newton',0,x0,options_CVode);
if nargout >= 4
    CVodeSensInit(length(theta),@rhsS,sx0,options_CVodes);
end

% Simulation
if nargout <= 3
    [status,~,x] = CVode(t(2:end),'Normal');
    X = [x0';x'];
    Y = rhsO(t,X,theta);
elseif nargout >=4
    [status,~,x,sx] = CVode(t(2:end),'Normal');
    X = [x0';x'];
    Y = rhsO(t,X,theta);
    SX = zeros(length(t),length(x0),length(theta));
    SX(1,:,:) = sx0;
    SX(2:end,:,:) = permute(sx,[3,1,2]);
    SY = rhsOS(t,X,SX,Y,theta);
end

% Evaluate reduced covariances
if nargout >= 3
XRed = EvalRedCov(X);
end
% Free memory
CVodeFree;

% Assign output
varargout{1} = X;
if nargout >= 2
    varargout{2} = Y;
end
if nargout >= 3
    varargout{3} = XRed;
end
if nargout >= 4
    varargout{4} = SX;
end
if nargout >= 5
    varargout{5} = SY;
end
if nargout >= 6
    error('Too many output arguments.');
end


%% RIGHT-HAND SIDE
function [dxdt,flag,new_data] = rhs(t,x,data) 

theta = data.theta;
dxdt = [theta(2)*x(2)-theta(1)*x(1)-x(8)*theta(7)-theta(7)*x(1)*x(4);...
        x(8)*theta(7)+theta(1)*x(1)-theta(2)*x(2)+theta(7)*x(1)*x(4);...
        theta(3)*x(2)-theta(4)*x(3);...
        theta(5)*x(3)-theta(6)*x(4);...
        2*x(6)*theta(2)-2*x(5)*theta(1)+x(8)*theta(7)-2*x(18)*theta(7)+theta(1)*x(1)+theta(2)*x(2)-2*x(5)*theta(7)*x(4)-2*x(8)*theta(7)*x(1)+theta(7)*x(1)*x(4);...
        x(5)*theta(1)-x(6)*theta(1)-x(6)*theta(2)-x(8)*theta(7)+x(9)*theta(2)+x(18)*theta(7)-x(21)*theta(7)-theta(1)*x(1)-theta(2)*x(2)+x(5)*theta(7)*x(4)+x(8)*theta(7)*x(1)-x(6)*theta(7)*x(4)-x(11)*theta(7)*x(1)-theta(7)*x(1)*x(4);...
        x(6)*theta(3)-x(7)*theta(1)-x(7)*theta(4)+x(10)*theta(2)-x(23)*theta(7)-x(7)*theta(7)*x(4)-x(13)*theta(7)*x(1);...
        x(7)*theta(5)-x(8)*theta(1)-x(8)*theta(6)+x(11)*theta(2)-x(24)*theta(7)-x(8)*theta(7)*x(4)-x(14)*theta(7)*x(1);...
        2*x(6)*theta(1)+x(8)*theta(7)-2*x(9)*theta(2)+2*x(21)*theta(7)+theta(1)*x(1)+theta(2)*x(2)+2*x(6)*theta(7)*x(4)+2*x(11)*theta(7)*x(1)+theta(7)*x(1)*x(4);...
        x(7)*theta(1)+x(9)*theta(3)-x(10)*theta(2)-x(10)*theta(4)+x(23)*theta(7)+x(7)*theta(7)*x(4)+x(13)*theta(7)*x(1);...
        x(8)*theta(1)-x(11)*theta(2)+x(10)*theta(5)-x(11)*theta(6)+x(24)*theta(7)+x(8)*theta(7)*x(4)+x(14)*theta(7)*x(1);...
        2*x(10)*theta(3)-2*x(12)*theta(4)+theta(3)*x(2)+theta(4)*x(3);...
        x(11)*theta(3)+x(12)*theta(5)-x(13)*theta(4)-x(13)*theta(6);...
        2*x(13)*theta(5)-2*x(14)*theta(6)+theta(5)*x(3)+theta(6)*x(4);...
        3*x(5)*theta(1)+3*x(6)*theta(2)-x(8)*theta(7)-3*x(15)*theta(1)+3*x(16)*theta(2)+3*x(18)*theta(7)-theta(1)*x(1)+theta(2)*x(2)+3*x(5)*x(8)*theta(7)+3*x(5)*theta(7)*x(4)+3*x(8)*theta(7)*x(1)-3*x(15)*theta(7)*x(4)-3*x(18)*theta(7)*x(1)-theta(7)*x(1)*x(4);...
        x(6)*theta(1)-2*x(5)*theta(1)-2*x(6)*theta(2)+x(8)*theta(7)+x(9)*theta(2)+x(15)*theta(1)-2*x(16)*theta(1)-x(16)*theta(2)-2*x(18)*theta(7)+2*x(19)*theta(2)+x(21)*theta(7)+theta(1)*x(1)-theta(2)*x(2)-x(5)*x(8)*theta(7)+2*x(6)*x(8)*theta(7)-2*x(5)*theta(7)*x(4)-2*x(8)*theta(7)*x(1)+x(6)*theta(7)*x(4)+x(11)*theta(7)*x(1)+x(15)*theta(7)*x(4)+x(18)*theta(7)*x(1)-2*x(16)*theta(7)*x(4)-2*x(21)*theta(7)*x(1)+theta(7)*x(1)*x(4);...
        x(7)*theta(1)+x(10)*theta(2)-2*x(17)*theta(1)+x(16)*theta(3)-x(17)*theta(4)+2*x(20)*theta(2)+x(23)*theta(7)+2*x(7)*x(8)*theta(7)+x(7)*theta(7)*x(4)+x(13)*theta(7)*x(1)-2*x(17)*theta(7)*x(4)-2*x(23)*theta(7)*x(1);...
        x(8)*theta(1)+x(11)*theta(2)-2*x(18)*theta(1)+x(17)*theta(5)-x(18)*theta(6)+2*x(21)*theta(2)+x(24)*theta(7)+2*x(8)^2*theta(7)+x(8)*theta(7)*x(4)+x(14)*theta(7)*x(1)-2*x(18)*theta(7)*x(4)-2*x(24)*theta(7)*x(1);...
        x(5)*theta(1)-2*x(6)*theta(1)+x(6)*theta(2)-x(8)*theta(7)-2*x(9)*theta(2)+2*x(16)*theta(1)+x(18)*theta(7)-x(19)*theta(1)-2*x(19)*theta(2)-2*x(21)*theta(7)+x(25)*theta(2)-theta(1)*x(1)+theta(2)*x(2)-2*x(6)*x(8)*theta(7)+x(8)*x(9)*theta(7)+x(5)*theta(7)*x(4)+x(8)*theta(7)*x(1)-2*x(6)*theta(7)*x(4)-2*x(11)*theta(7)*x(1)+2*x(16)*theta(7)*x(4)+2*x(21)*theta(7)*x(1)-x(19)*theta(7)*x(4)-x(27)*theta(7)*x(1)-theta(7)*x(1)*x(4);...
        x(17)*theta(1)-x(10)*theta(2)-x(7)*theta(1)-x(20)*theta(1)+x(19)*theta(3)-x(20)*theta(2)-x(20)*theta(4)-x(23)*theta(7)+x(26)*theta(2)-x(7)*x(8)*theta(7)+x(8)*x(10)*theta(7)-x(7)*theta(7)*x(4)-x(13)*theta(7)*x(1)+x(17)*theta(7)*x(4)-x(20)*theta(7)*x(4)+x(23)*theta(7)*x(1)-x(29)*theta(7)*x(1);...
        x(18)*theta(1)-x(11)*theta(2)-x(8)*theta(1)-x(21)*theta(1)-x(21)*theta(2)+x(20)*theta(5)-x(21)*theta(6)-x(24)*theta(7)+x(27)*theta(2)-x(8)^2*theta(7)+x(8)*x(11)*theta(7)-x(8)*theta(7)*x(4)-x(14)*theta(7)*x(1)+x(18)*theta(7)*x(4)-x(21)*theta(7)*x(4)+x(24)*theta(7)*x(1)-x(30)*theta(7)*x(1);...
        x(6)*theta(3)+x(7)*theta(4)+2*x(20)*theta(3)-x(22)*theta(1)-2*x(22)*theta(4)+x(28)*theta(2)+x(8)*x(12)*theta(7)-x(22)*theta(7)*x(4)-x(32)*theta(7)*x(1);...
        x(21)*theta(3)-x(23)*theta(1)+x(22)*theta(5)-x(23)*theta(4)-x(23)*theta(6)+x(29)*theta(2)+x(8)*x(13)*theta(7)-x(23)*theta(7)*x(4)-x(33)*theta(7)*x(1);...
        x(7)*theta(5)+x(8)*theta(6)+2*x(23)*theta(5)-x(24)*theta(1)-2*x(24)*theta(6)+x(30)*theta(2)+x(8)*x(14)*theta(7)-x(24)*theta(7)*x(4)-x(34)*theta(7)*x(1);...
        3*x(6)*theta(1)+x(8)*theta(7)+3*x(9)*theta(2)+3*x(19)*theta(1)+3*x(21)*theta(7)-3*x(25)*theta(2)+theta(1)*x(1)-theta(2)*x(2)-3*x(8)*x(9)*theta(7)+3*x(6)*theta(7)*x(4)+3*x(11)*theta(7)*x(1)+3*x(19)*theta(7)*x(4)+3*x(27)*theta(7)*x(1)+theta(7)*x(1)*x(4);...
        x(7)*theta(1)+x(10)*theta(2)+2*x(20)*theta(1)+x(23)*theta(7)+x(25)*theta(3)-2*x(26)*theta(2)-x(26)*theta(4)-2*x(8)*x(10)*theta(7)+x(7)*theta(7)*x(4)+x(13)*theta(7)*x(1)+2*x(20)*theta(7)*x(4)+2*x(29)*theta(7)*x(1);...
        x(8)*theta(1)+x(11)*theta(2)+2*x(21)*theta(1)+x(24)*theta(7)-2*x(27)*theta(2)+x(26)*theta(5)-x(27)*theta(6)-2*x(8)*x(11)*theta(7)+x(8)*theta(7)*x(4)+x(14)*theta(7)*x(1)+2*x(21)*theta(7)*x(4)+2*x(30)*theta(7)*x(1);...
        x(9)*theta(3)+x(10)*theta(4)+x(22)*theta(1)+2*x(26)*theta(3)-x(28)*theta(2)-2*x(28)*theta(4)-x(8)*x(12)*theta(7)+x(22)*theta(7)*x(4)+x(32)*theta(7)*x(1);...
        x(23)*theta(1)+x(27)*theta(3)-x(29)*theta(2)+x(28)*theta(5)-x(29)*theta(4)-x(29)*theta(6)-x(8)*x(13)*theta(7)+x(23)*theta(7)*x(4)+x(33)*theta(7)*x(1);...
        x(10)*theta(5)+x(11)*theta(6)+x(24)*theta(1)+2*x(29)*theta(5)-x(30)*theta(2)-2*x(30)*theta(6)-x(8)*x(14)*theta(7)+x(24)*theta(7)*x(4)+x(34)*theta(7)*x(1);...
        3*x(10)*theta(3)+3*x(12)*theta(4)+3*x(28)*theta(3)-3*x(31)*theta(4)+theta(3)*x(2)-theta(4)*x(3);...
        x(11)*theta(3)+x(13)*theta(4)+2*x(29)*theta(3)+x(31)*theta(5)-2*x(32)*theta(4)-x(32)*theta(6);...
        x(12)*theta(5)+x(13)*theta(6)+x(30)*theta(3)+2*x(32)*theta(5)-x(33)*theta(4)-2*x(33)*theta(6);...
        3*x(13)*theta(5)+3*x(14)*theta(6)+3*x(33)*theta(5)-3*x(34)*theta(6)+theta(5)*x(3)-theta(6)*x(4)];

flag = 0;
new_data = [];

%% RIGHT-HAND SIDE OF SENSITIVITIES
function [dsxdt,flag,new_data] = rhsS(t,x,dxdt,sx,data) 

theta = data.theta;
J = jacfn(t,x,dxdt,data);
dfdtheta = [-x(1),x(2),0,0,0,0,-x(8)-x(1)*x(4),0;...
              x(1),-x(2),0,0,0,0,x(8)+x(1)*x(4),0;...
              0,0,x(2),-x(3),0,0,0,0;...
              0,0,0,0,x(3),-x(4),0,0;...
              x(1)-2*x(5),2*x(6)+x(2),0,0,0,0,x(8)-2*x(18)-2*x(5)*x(4)-2*x(8)*x(1)+x(1)*x(4),0;...
              x(5)-x(6)-x(1),x(9)-x(6)-x(2),0,0,0,0,x(18)-x(8)-x(21)+x(5)*x(4)+x(8)*x(1)-x(6)*x(4)-x(11)*x(1)-x(1)*x(4),0;...
              -x(7),x(10),x(6),-x(7),0,0,-x(23)-x(7)*x(4)-x(13)*x(1),0;...
              -x(8),x(11),0,0,x(7),-x(8),-x(24)-x(8)*x(4)-x(14)*x(1),0;...
              2*x(6)+x(1),x(2)-2*x(9),0,0,0,0,x(8)+2*x(21)+2*x(6)*x(4)+2*x(11)*x(1)+x(1)*x(4),0;...
              x(7),-x(10),x(9),-x(10),0,0,x(23)+x(7)*x(4)+x(13)*x(1),0;...
              x(8),-x(11),0,0,x(10),-x(11),x(24)+x(8)*x(4)+x(14)*x(1),0;...
              0,0,2*x(10)+x(2),x(3)-2*x(12),0,0,0,0;...
              0,0,x(11),-x(13),x(12),-x(13),0,0;...
              0,0,0,0,2*x(13)+x(3),x(4)-2*x(14),0,0;...
              3*x(5)-3*x(15)-x(1),3*x(6)+3*x(16)+x(2),0,0,0,0,3*x(18)-x(8)+3*x(5)*x(4)+3*x(8)*x(1)-3*x(15)*x(4)-3*x(18)*x(1)-x(1)*x(4)+3*x(5)*x(8),0;...
              x(6)-2*x(5)+x(15)-2*x(16)+x(1),x(9)-2*x(6)-x(16)+2*x(19)-x(2),0,0,0,0,x(8)-2*x(18)+x(21)-2*x(5)*x(4)-2*x(8)*x(1)+x(6)*x(4)+x(11)*x(1)+x(15)*x(4)+x(18)*x(1)-2*x(16)*x(4)-2*x(21)*x(1)+x(1)*x(4)-x(5)*x(8)+2*x(6)*x(8),0;...
              x(7)-2*x(17),x(10)+2*x(20),x(16),-x(17),0,0,x(23)+x(7)*x(4)+x(13)*x(1)-2*x(17)*x(4)-2*x(23)*x(1)+2*x(7)*x(8),0;...
              x(8)-2*x(18),x(11)+2*x(21),0,0,x(17),-x(18),x(24)+x(8)*x(4)+x(14)*x(1)-2*x(18)*x(4)-2*x(24)*x(1)+2*x(8)^2,0;...
              x(5)-2*x(6)+2*x(16)-x(19)-x(1),x(6)-2*x(9)-2*x(19)+x(25)+x(2),0,0,0,0,x(18)-x(8)-2*x(21)+x(5)*x(4)+x(8)*x(1)-2*x(6)*x(4)-2*x(11)*x(1)+2*x(16)*x(4)+2*x(21)*x(1)-x(19)*x(4)-x(27)*x(1)-x(1)*x(4)-2*x(6)*x(8)+x(8)*x(9),0;...
              x(17)-x(7)-x(20),x(26)-x(20)-x(10),x(19),-x(20),0,0,x(17)*x(4)-x(7)*x(4)-x(13)*x(1)-x(23)-x(20)*x(4)+x(23)*x(1)-x(29)*x(1)-x(7)*x(8)+x(8)*x(10),0;...
              x(18)-x(8)-x(21),x(27)-x(21)-x(11),0,0,x(20),-x(21),x(18)*x(4)-x(8)*x(4)-x(14)*x(1)-x(24)-x(21)*x(4)+x(24)*x(1)-x(30)*x(1)-x(8)^2+x(8)*x(11),0;...
              -x(22),x(28),x(6)+2*x(20),x(7)-2*x(22),0,0,x(8)*x(12)-x(32)*x(1)-x(22)*x(4),0;...
              -x(23),x(29),x(21),-x(23),x(22),-x(23),x(8)*x(13)-x(33)*x(1)-x(23)*x(4),0;...
              -x(24),x(30),0,0,x(7)+2*x(23),x(8)-2*x(24),x(8)*x(14)-x(34)*x(1)-x(24)*x(4),0;...
              3*x(6)+3*x(19)+x(1),3*x(9)-3*x(25)-x(2),0,0,0,0,x(8)+3*x(21)+3*x(6)*x(4)+3*x(11)*x(1)+3*x(19)*x(4)+3*x(27)*x(1)+x(1)*x(4)-3*x(8)*x(9),0;...
              x(7)+2*x(20),x(10)-2*x(26),x(25),-x(26),0,0,x(23)+x(7)*x(4)+x(13)*x(1)+2*x(20)*x(4)+2*x(29)*x(1)-2*x(8)*x(10),0;...
              x(8)+2*x(21),x(11)-2*x(27),0,0,x(26),-x(27),x(24)+x(8)*x(4)+x(14)*x(1)+2*x(21)*x(4)+2*x(30)*x(1)-2*x(8)*x(11),0;...
              x(22),-x(28),x(9)+2*x(26),x(10)-2*x(28),0,0,x(22)*x(4)+x(32)*x(1)-x(8)*x(12),0;...
              x(23),-x(29),x(27),-x(29),x(28),-x(29),x(23)*x(4)+x(33)*x(1)-x(8)*x(13),0;...
              x(24),-x(30),0,0,x(10)+2*x(29),x(11)-2*x(30),x(24)*x(4)+x(34)*x(1)-x(8)*x(14),0;...
              0,0,3*x(10)+3*x(28)+x(2),3*x(12)-3*x(31)-x(3),0,0,0,0;...
              0,0,x(11)+2*x(29),x(13)-2*x(32),x(31),-x(32),0,0;...
              0,0,x(30),-x(33),x(12)+2*x(32),x(13)-2*x(33),0,0;...
              0,0,0,0,3*x(13)+3*x(33)+x(3),3*x(14)-3*x(34)-x(4),0,0];

dsxdt = J*sx + dfdtheta;

flag = 0;
new_data = [];

%% JACOBIAN
function [J,flag,new_data] = jacfn(t,x,dxdt,data) 

theta = data.theta;
J = [-theta(1)-theta(7)*x(4),theta(2),0,-theta(7)*x(1),0,0,0,-theta(7),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     theta(1)+theta(7)*x(4),-theta(2),0,theta(7)*x(1),0,0,0,theta(7),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     0,theta(3),-theta(4),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     0,0,theta(5),-theta(6),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     theta(1)-2*x(8)*theta(7)+theta(7)*x(4),theta(2),0,theta(7)*x(1)-2*x(5)*theta(7),-2*theta(1)-2*theta(7)*x(4),2*theta(2),0,theta(7)-2*theta(7)*x(1),0,0,0,0,0,0,0,0,0,-2*theta(7),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     x(8)*theta(7)-theta(1)-x(11)*theta(7)-theta(7)*x(4),-theta(2),0,x(5)*theta(7)-x(6)*theta(7)-theta(7)*x(1),theta(1)+theta(7)*x(4),-theta(1)-theta(2)-theta(7)*x(4),0,theta(7)*x(1)-theta(7),theta(2),0,-theta(7)*x(1),0,0,0,0,0,0,theta(7),0,0,-theta(7),0,0,0,0,0,0,0,0,0,0,0,0,0;...
     -x(13)*theta(7),0,0,-x(7)*theta(7),0,theta(3),-theta(1)-theta(4)-theta(7)*x(4),0,0,theta(2),0,0,-theta(7)*x(1),0,0,0,0,0,0,0,0,0,-theta(7),0,0,0,0,0,0,0,0,0,0,0;...
     -x(14)*theta(7),0,0,-x(8)*theta(7),0,0,theta(5),-theta(1)-theta(6)-theta(7)*x(4),0,0,theta(2),0,0,-theta(7)*x(1),0,0,0,0,0,0,0,0,0,-theta(7),0,0,0,0,0,0,0,0,0,0;...
     theta(1)+2*x(11)*theta(7)+theta(7)*x(4),theta(2),0,2*x(6)*theta(7)+theta(7)*x(1),0,2*theta(1)+2*theta(7)*x(4),0,theta(7),-2*theta(2),0,2*theta(7)*x(1),0,0,0,0,0,0,0,0,0,2*theta(7),0,0,0,0,0,0,0,0,0,0,0,0,0;...
     x(13)*theta(7),0,0,x(7)*theta(7),0,0,theta(1)+theta(7)*x(4),0,theta(3),-theta(2)-theta(4),0,0,theta(7)*x(1),0,0,0,0,0,0,0,0,0,theta(7),0,0,0,0,0,0,0,0,0,0,0;...
     x(14)*theta(7),0,0,x(8)*theta(7),0,0,0,theta(1)+theta(7)*x(4),0,theta(5),-theta(2)-theta(6),0,0,theta(7)*x(1),0,0,0,0,0,0,0,0,0,theta(7),0,0,0,0,0,0,0,0,0,0;...
     0,theta(3),theta(4),0,0,0,0,0,0,2*theta(3),0,-2*theta(4),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     0,0,0,0,0,0,0,0,0,0,theta(3),theta(5),-theta(4)-theta(6),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     0,0,theta(5),theta(6),0,0,0,0,0,0,0,0,2*theta(5),-2*theta(6),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     3*x(8)*theta(7)-theta(1)-3*x(18)*theta(7)-theta(7)*x(4),theta(2),0,3*x(5)*theta(7)-3*x(15)*theta(7)-theta(7)*x(1),3*theta(1)+3*x(8)*theta(7)+3*theta(7)*x(4),3*theta(2),0,3*x(5)*theta(7)-theta(7)+3*theta(7)*x(1),0,0,0,0,0,0,-3*theta(1)-3*theta(7)*x(4),3*theta(2),0,3*theta(7)-3*theta(7)*x(1),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
     theta(1)-2*x(8)*theta(7)+x(11)*theta(7)+x(18)*theta(7)-2*x(21)*theta(7)+theta(7)*x(4),-theta(2),0,x(6)*theta(7)-2*x(5)*theta(7)+x(15)*theta(7)-2*x(16)*theta(7)+theta(7)*x(1),-2*theta(1)-x(8)*theta(7)-2*theta(7)*x(4),theta(1)-2*theta(2)+2*x(8)*theta(7)+theta(7)*x(4),0,theta(7)-x(5)*theta(7)+2*x(6)*theta(7)-2*theta(7)*x(1),theta(2),0,theta(7)*x(1),0,0,0,theta(1)+theta(7)*x(4),-2*theta(1)-theta(2)-2*theta(7)*x(4),0,theta(7)*x(1)-2*theta(7),2*theta(2),0,theta(7)-2*theta(7)*x(1),0,0,0,0,0,0,0,0,0,0,0,0,0;...
     x(13)*theta(7)-2*x(23)*theta(7),0,0,x(7)*theta(7)-2*x(17)*theta(7),0,0,theta(1)+2*x(8)*theta(7)+theta(7)*x(4),2*x(7)*theta(7),0,theta(2),0,0,theta(7)*x(1),0,0,theta(3),-2*theta(1)-theta(4)-2*theta(7)*x(4),0,0,2*theta(2),0,0,theta(7)-2*theta(7)*x(1),0,0,0,0,0,0,0,0,0,0,0;...
     x(14)*theta(7)-2*x(24)*theta(7),0,0,x(8)*theta(7)-2*x(18)*theta(7),0,0,0,theta(1)+4*x(8)*theta(7)+theta(7)*x(4),0,0,theta(2),0,0,theta(7)*x(1),0,0,theta(5),-2*theta(1)-theta(6)-2*theta(7)*x(4),0,0,2*theta(2),0,0,theta(7)-2*theta(7)*x(1),0,0,0,0,0,0,0,0,0,0;...
     x(8)*theta(7)-theta(1)-2*x(11)*theta(7)+2*x(21)*theta(7)-x(27)*theta(7)-theta(7)*x(4),theta(2),0,x(5)*theta(7)-2*x(6)*theta(7)+2*x(16)*theta(7)-x(19)*theta(7)-theta(7)*x(1),theta(1)+theta(7)*x(4),theta(2)-2*theta(1)-2*x(8)*theta(7)-2*theta(7)*x(4),0,x(9)*theta(7)-2*x(6)*theta(7)-theta(7)+theta(7)*x(1),x(8)*theta(7)-2*theta(2),0,-2*theta(7)*x(1),0,0,0,0,2*theta(1)+2*theta(7)*x(4),0,theta(7),-theta(1)-2*theta(2)-theta(7)*x(4),0,2*theta(7)*x(1)-2*theta(7),0,0,0,theta(2),0,-theta(7)*x(1),0,0,0,0,0,0,0;...
     x(23)*theta(7)-x(13)*theta(7)-x(29)*theta(7),0,0,x(17)*theta(7)-x(7)*theta(7)-x(20)*theta(7),0,0,-theta(1)-x(8)*theta(7)-theta(7)*x(4),x(10)*theta(7)-x(7)*theta(7),0,x(8)*theta(7)-theta(2),0,0,-theta(7)*x(1),0,0,0,theta(1)+theta(7)*x(4),0,theta(3),-theta(1)-theta(2)-theta(4)-theta(7)*x(4),0,0,theta(7)*x(1)-theta(7),0,0,theta(2),0,0,-theta(7)*x(1),0,0,0,0,0;...
     x(24)*theta(7)-x(14)*theta(7)-x(30)*theta(7),0,0,x(18)*theta(7)-x(8)*theta(7)-x(21)*theta(7),0,0,0,x(11)*theta(7)-2*x(8)*theta(7)-theta(1)-theta(7)*x(4),0,0,x(8)*theta(7)-theta(2),0,0,-theta(7)*x(1),0,0,0,theta(1)+theta(7)*x(4),0,theta(5),-theta(1)-theta(2)-theta(6)-theta(7)*x(4),0,0,theta(7)*x(1)-theta(7),0,0,theta(2),0,0,-theta(7)*x(1),0,0,0,0;...
     -x(32)*theta(7),0,0,-x(22)*theta(7),0,theta(3),theta(4),x(12)*theta(7),0,0,0,x(8)*theta(7),0,0,0,0,0,0,0,2*theta(3),0,-theta(1)-2*theta(4)-theta(7)*x(4),0,0,0,0,0,theta(2),0,0,0,-theta(7)*x(1),0,0;...
     -x(33)*theta(7),0,0,-x(23)*theta(7),0,0,0,x(13)*theta(7),0,0,0,0,x(8)*theta(7),0,0,0,0,0,0,0,theta(3),theta(5),-theta(1)-theta(4)-theta(6)-theta(7)*x(4),0,0,0,0,0,theta(2),0,0,0,-theta(7)*x(1),0;...
     -x(34)*theta(7),0,0,-x(24)*theta(7),0,0,theta(5),theta(6)+x(14)*theta(7),0,0,0,0,0,x(8)*theta(7),0,0,0,0,0,0,0,0,2*theta(5),-theta(1)-2*theta(6)-theta(7)*x(4),0,0,0,0,0,theta(2),0,0,0,-theta(7)*x(1);...
     theta(1)+3*x(11)*theta(7)+3*x(27)*theta(7)+theta(7)*x(4),-theta(2),0,3*x(6)*theta(7)+3*x(19)*theta(7)+theta(7)*x(1),0,3*theta(1)+3*theta(7)*x(4),0,theta(7)-3*x(9)*theta(7),3*theta(2)-3*x(8)*theta(7),0,3*theta(7)*x(1),0,0,0,0,0,0,0,3*theta(1)+3*theta(7)*x(4),0,3*theta(7),0,0,0,-3*theta(2),0,3*theta(7)*x(1),0,0,0,0,0,0,0;...
     x(13)*theta(7)+2*x(29)*theta(7),0,0,x(7)*theta(7)+2*x(20)*theta(7),0,0,theta(1)+theta(7)*x(4),-2*x(10)*theta(7),0,theta(2)-2*x(8)*theta(7),0,0,theta(7)*x(1),0,0,0,0,0,0,2*theta(1)+2*theta(7)*x(4),0,0,theta(7),0,theta(3),-2*theta(2)-theta(4),0,0,2*theta(7)*x(1),0,0,0,0,0;...
     x(14)*theta(7)+2*x(30)*theta(7),0,0,x(8)*theta(7)+2*x(21)*theta(7),0,0,0,theta(1)-2*x(11)*theta(7)+theta(7)*x(4),0,0,theta(2)-2*x(8)*theta(7),0,0,theta(7)*x(1),0,0,0,0,0,0,2*theta(1)+2*theta(7)*x(4),0,0,theta(7),0,theta(5),-2*theta(2)-theta(6),0,0,2*theta(7)*x(1),0,0,0,0;...
     x(32)*theta(7),0,0,x(22)*theta(7),0,0,0,-x(12)*theta(7),theta(3),theta(4),0,-x(8)*theta(7),0,0,0,0,0,0,0,0,0,theta(1)+theta(7)*x(4),0,0,0,2*theta(3),0,-theta(2)-2*theta(4),0,0,0,theta(7)*x(1),0,0;...
     x(33)*theta(7),0,0,x(23)*theta(7),0,0,0,-x(13)*theta(7),0,0,0,0,-x(8)*theta(7),0,0,0,0,0,0,0,0,0,theta(1)+theta(7)*x(4),0,0,0,theta(3),theta(5),-theta(2)-theta(4)-theta(6),0,0,0,theta(7)*x(1),0;...
     x(34)*theta(7),0,0,x(24)*theta(7),0,0,0,-x(14)*theta(7),0,theta(5),theta(6),0,0,-x(8)*theta(7),0,0,0,0,0,0,0,0,0,theta(1)+theta(7)*x(4),0,0,0,0,2*theta(5),-theta(2)-2*theta(6),0,0,0,theta(7)*x(1);...
     0,theta(3),-theta(4),0,0,0,0,0,0,3*theta(3),0,3*theta(4),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3*theta(3),0,0,-3*theta(4),0,0,0;...
     0,0,0,0,0,0,0,0,0,0,theta(3),0,theta(4),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2*theta(3),0,theta(5),-2*theta(4)-theta(6),0,0;...
     0,0,0,0,0,0,0,0,0,0,0,theta(5),theta(6),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,theta(3),0,2*theta(5),-theta(4)-2*theta(6),0;...
     0,0,theta(5),-theta(6),0,0,0,0,0,0,0,0,3*theta(5),3*theta(6),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3*theta(5),-3*theta(6)];
flag = 0;
new_data = [];

%% OUTPUT MAP
function y = rhsO(t,x,theta) 

y = [x(:,3),x(:,3)+x(:,4),x(:,12),x(:,12)+x(:,13),x(:,12)+2*x(:,13)+x(:,14),x(:,31),x(:,31)+x(:,32),x(:,31)+2*x(:,32)+x(:,33),x(:,31)+3*x(:,32)+3*x(:,33)+x(:,34)];


%% OUTPUT MAP OF SENSITIVITIES
function sy = rhsOS(t,x,sx,y,theta) 

sy = zeros(length(t),size(y,2),length(theta));
for k = 1:length(t)
    dHdx = [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
            0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
            0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
            0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
            0,0,0,0,0,0,0,0,0,0,0,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;...
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0;...
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0;...
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,1,0;...
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,3,3,0];
    dHdtheta = [0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0;...
                0,0,0,0,0,0,0,0];
    sy(k,:,:) = dHdx*squeeze(sx(k,:,:)) + dHdtheta;
end


%% INITIAL CONDITIONS FOR STATE
function x0 = x0fun(theta) 

x0 = [1;...
      0;...
      4;...
      10;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0;...
      0];


%% INITIAL CONDITIONS FOR STATE SENSITIVITY
function sx0 = sx0fun(theta) 

sx0 = [0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0;...
       0,0,0,0,0,0,0,0];


%% EVALUAED REDUCED COVARIANCES
function xred = EvalRedCov(x) 

xred =[];

