function X = randomBigInt(N)
% RANDOMBIGINT Generate random N-bit java.math.BigInteger uniformly.
% Ensures the top bit is set to get full N-bit width.

if N <= 0, error('N must be positive'); end
rnd = java.security.SecureRandom();
% generate random bytes
numBytes = ceil(N/8);
b = zeros(1,numBytes,'int8');
rnd.nextBytes(int8(b)); % fills b with random bytes
% convert to positive BigInteger
X = java.math.BigInteger(1, int8(b));
% ensure it is within N bits by masking/truncating
mask = java.math.BigInteger.ONE.shiftLeft(N).subtract(java.math.BigInteger.ONE);
X = X.and(mask);
% set MSB to 1 to make it exactly N-bit (avoids small numbers)
X = X.setBit(N-1);
end