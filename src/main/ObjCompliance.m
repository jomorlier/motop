function [ C, dC ] = ObjCompliance( s )
%OBJCOMPLIANCE calculates the compliance C and the first order compliance
%derivative dC with respect to x for a given design x with global stiffness
%K and element unit stiffess Ke0 which is loaded with global force vector F
%
%   SYNTAX
%   C = OBJCOMPLIANCE( s )
%   [C,dC] = OBJCOMPLIANCE( s )
%
%   DESCRIPTION
%   Compliance is a scalar measure of a strucutres stiffness such that the 
%   compliance is low for a strucutre with high stiffness.
%
%   OBJCOMPLIANCE computes the compliance as:
%
%       C = sum(E*ue'*Ke0*ue),
%
%   and the first order derivative of C with respect to x according to:
%
%       dC = -dE*ue'*Ke0*ue,
%
%   where ue is the elemnt displacement solved from the equilibrium
%   equation K*u=F.
%
%   INPUT ARGUMENTS
%   s   a struct with at least the following fields
%       x      vector of design parameters, size(x) = (nelem x 1) where
%              nelem is the number of elements; 0 <= x0 <= 1
%       xp     prescribed parameters matrix, size(xp) = (npx x 2) where
%              npx is the number of prescribed x parameters; each row in xp
%              is [e, pv] where e is the element number that is prescribed
%              and 0 <= pv <= 1 is the prescribed value
%       Edof   elemnet degrees of freedom, size(Edof) = (nelem x ndofe)
%              where ndofe is the number of degrees of freedom per element;
%              one row for each element: [u1,u2,u3,...,un]
%       bc     boundary condition matrix size(bc) = (nbc x 2), nbc is the
%              number of boundary conditions; each row in bc is [dofn, pv]
%              where dofn is the degree of freedom number that is
%              prescribed and pv is the prescribed value
%       F      global load vector, size(F) = (ndof x 1) where ndof is the
%              total number of degrees of freedom
%       K      global stiffness matrix, size(K) = (ndof x ndof)
%       Ke0    element unit stiffness matrix,
%              size(Ke0) = (ndofe x ndofe)
%       E      vector of element Young's moduls, size(E) = (nelem x 1)
%       dE     first order derivatives of element Young's modulus with
%              respect to x, size(dE) = (nelem x 1)
%
%   OUTPUT ARGUMENTS
%       C      compliance
%       dC     sensitivity (first order derivative with respect to the
%              parameters x)

% LAST MODIFIED: A Sehlstrom    2013-05-23
% Copyright (C)  A Sehlstrom

% Parse inputs ------------------------------------------------------------
parseo = inputParser;
addRequired(parseo,'s', @isstruct);
parseo.parse(s);

% Extract
x    = s.x;
xp   = s.xp;
Edof = s.Edof;
bc   = s.bc;
F    = s.F;
K    = s.K;
Ke0  = s.Ke0;
E    = s.E;
dE   = s.dE;

% Input checks ------------------------------------------------------------
if size(x,2) ~= 1
    error('OCompliance:argChk', '"x" must be a row vector of length nelem');
end

if size(x,1) ~= size(Edof,1)
    error('OCompliance:argChk', '"x" and "Edof" has to have the same number of rows');
end

if isnan(E)
    error('OCompliance:argChk', '"E" has to be specified in struct "s"');
elseif size(x) ~= size(E)
    error('OCompliance:argChk', '"x" and "E" has to have the same size');
end

if isnan(dE)
    error('OCompliance:argChk', '"dE" has to be specified in struct "s"');
elseif size(x) ~= size(dE)
    error('OCompliance:argChk', '"x" and "dE" has to have the same size');
end

if isnan(Ke0)
    error('OCompliance:argChk', '"Ke0" has to be specified in struct "s"');
elseif size(Ke0,1) ~= size(Edof,2)
    error('OCompliance:argChk', '"Ke0" has not the same number of DOFs as specified in "Edof"');
end

if isnan(K)
    error('OCompliance:argChk', '"K" has to be specified in struct "s"');
elseif size(K,1) ~= max(max(Edof))
    error('OCompliance:argChk', 'Number of DOFs in "K" and in "Edof" is not equal');
end

% Setup -------------------------------------------------------------------
% Make sure prescribed values are prescribed
if size(xp) ~= [0,0]
    x(xp(:,1)) = xp(:,2);
end

% Solve displacements -----------------------------------------------------
if exist('solveq','file') ~=2
    error('OCompliance:CALFEM','CALFEM "solveq" function has to be on the Matlab path')
end
u = solveq(K,F,bc);                       % solve using CALFEM solveq

% Determin objective ------------------------------------------------------
% Initialize
C = 0.;
if nargout > 1
    dC = zeros(length(x), 1);
end

% Compute
for ii = 1:length(x)
    ue  = u(Edof(ii,:));                  % Element displacements
    ESE = ue' * Ke0 * ue;                 % Element specific energy
    
    % Compliance
    Ce  = E(ii) * ESE;                    % Element compliance contribution
    C   = C + Ce;                         % Total compliance
    
    % Compliance sensitivity
    if nargout > 1
        dC(ii) = - dE(ii) * ESE;
    end
end

end

