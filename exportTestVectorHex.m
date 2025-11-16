function exportTestVectorHex(filename, A, B, C, N)
% EXPORTTESTVECTORHEX Write test vector file in hex lines:
%   A_hex
%   B_hex
%   C_hex
% Each value is zero-padded to width N (A,B) or 2N (C). No prefix.
%
% filename: full path to output file
% A,B,C: java.math.BigInteger
% N: bit width of A/B

if ~isa(A,'java.math.BigInteger') || ~isa(B,'java.math.BigInteger') || ~isa(C,'java.math.BigInteger')
    error('A,B,C must be java.math.BigInteger');
end

% convert to hex strings
Ahex = bigIntToPaddedHex(A, N);
Bhex = bigIntToPaddedHex(B, N);
Chex = bigIntToPaddedHex(C, 2*N);

fid = fopen(filename,'w');
if fid == -1, error('Cannot open %s for writing', filename); end
fprintf(fid, '%s\n%s\n%s\n', Ahex, Bhex, Chex);
fclose(fid);
end

function hx = bigIntToPaddedHex(X, bits)
% returns lowercase hex string without 0x, padded to ceil(bits/4) hex digits
hexStr = char(X.toString(16)); % may be without leading zeros
hexDigits = ceil(bits/4);
% remove sign if any (should be positive)
if startsWith(hexStr, '-')
    error('Negative big integer not expected');
end
% pad with leading zeros
if length(hexStr) < hexDigits
    hx = [repmat('0',1,hexDigits-length(hexStr)) hexStr];
else
    % truncate higher bits if longer than needed (keep least significant digits)
    hx = hexStr(max(1, length(hexStr)-hexDigits+1):end);
end
end