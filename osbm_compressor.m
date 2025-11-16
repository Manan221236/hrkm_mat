function C = osbm_compressor(A, B, N)
% OSBM_COMPRESSOR: Optimized schoolbook multiplication.
% Implements partial-product generation and adds them using a lightweight
% accumulator loop. This is functional (uses BigInteger arithmetic) but
% structured similar to hardware partial-product accumulation.
% Inputs A,B as java.math.BigInteger, N bits width (use to mask/truncate)
%
% Output C as java.math.BigInteger product.

% Mask inputs to N bits
if N <= 0, error('N must be positive'); end
mask = java.math.BigInteger.ONE.shiftLeft(N).subtract(java.math.BigInteger.ONE);
A = A.and(mask);
B = B.and(mask);

C = java.math.BigInteger.ZERO;

% We iterate over set bits in B and shift A accordingly.
% For efficiency we examine B word-by-word.
bstr = char(B.toString(2));
% pad to N bits
if length(bstr) < N
    bstr = [repmat('0',1,N-length(bstr)) bstr];
elseif length(bstr) > N
    bstr = bstr(end-N+1:end);
end

% accumulate partial products
for i = 0:(N-1)
    if bstr(end-i) == '1' % LSB at end
        C = C.add(A.shiftLeft(i));
    end
end
% mask result to 2*N bits (not strictly necessary but explicit)
% (2*N bits mask)
% cmask = java.math.BigInteger.ONE.shiftLeft(2*N).subtract(java.math.BigInteger.ONE);
% C = C.and(cmask);

end