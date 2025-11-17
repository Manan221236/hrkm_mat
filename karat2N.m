function C = karat2N(A, B, N, base_bits)
% KARAT2N: Hybrid Recursive Karatsuba multiplication (functional golden model)
% Inputs:
%   A, B      - java.math.BigInteger
%   N         - bit-width (positive integer)
%   base_bits - recursion cutoff width (e.g., 16)
% Output:
%   C - java.math.BigInteger (product)

% Ensure inputs are BigInteger
if ~isa(A, 'java.math.BigInteger')
    error('A must be java.math.BigInteger');
end
if ~isa(B, 'java.math.BigInteger')
    error('B must be java.math.BigInteger');
end

% Base case
if N <= base_bits
    C = osbm_compressor(A, B, N);
    return;
end

% split width
half = floor(N/2);

% mask = (1 << half) - 1
mask = java.math.BigInteger.ONE.shiftLeft(half).subtract(java.math.BigInteger.ONE);

A0 = A.and(mask);
A1 = A.shiftRight(half);
B0 = B.and(mask);
B1 = B.shiftRight(half);

% recursive parts
C0 = karat2N(A0, B0, half, base_bits);
C2 = karat2N(A1, B1, N-half, base_bits);
sumA = A0.add(A1);
sumB = B0.add(B1);
Csum = karat2N(sumA, sumB, half+1, base_bits); % note half+1 to handle carry
C1 = Csum.subtract(C0).subtract(C2);

% recombine
C = C2.shiftLeft(2*half).add(C1.shiftLeft(half)).add(C0);
end