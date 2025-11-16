function generate_hrkm_hex_files(arg1, arg2, arg3)
% generate_hrkm_hex_files(...) -- robust generator + validator for HRKM TB
%
% Usage:
%   generate_hrkm_hex_files(N, outdir)
%     - create N random vectors + corner cases, write to outdir
%
%   generate_hrkm_hex_files(outdir, hexA, hexB)
%     - use provided cell arrays hexA, hexB (each N x 1) and compute golden
%
%   generate_hrkm_hex_files(outdir)
%     - default N = 50 vectors written to 'results'
%
% Output files (in outdir):
%   testvecs_128b_base16_all.hex
%   testvecs_B_128b_base16_all.hex
%   golden_128b_base16_all.hex
%
% Implementation notes:
%  - Uses java.math.BigInteger for arbitrary precision operations (no doubles).
%  - Pads hex strings to exact widths (A,B = 128 bits = 32 hex digits; C = 256 bits = 64 hex digits).
%  - Writes one hex string per line (no spaces, no '0x', uppercase).
%  - Includes a validator that prints first 5 lines and checks line widths.

% ---------- Parse arguments ----------
if nargin == 0
    outdir = 'results';
    N = 50;
    hexA = [];
    hexB = [];
elseif nargin == 1
    if isnumeric(arg1)
        N = arg1;
        outdir = 'results';
        hexA = []; hexB = [];
    else
        outdir = arg1;
        N = 50;
        hexA = []; hexB = [];
    end
elseif nargin == 2
    if isnumeric(arg1) && ischar(arg2)
        N = arg1; outdir = arg2; hexA = []; hexB = [];
    else
        error('Two-arg form must be (N, outdir) or (outdir, hexA) -- use three args for custom A/B.');
    end
elseif nargin == 3
    % form: generate_hrkm_hex_files(outdir, hexA, hexB)
    outdir = arg1;
    hexA = arg2;
    hexB = arg3;
    if ~iscell(hexA) || ~iscell(hexB)
        error('hexA and hexB must be cell arrays of hex strings.');
    end
    if numel(hexA) ~= numel(hexB)
        error('hexA and hexB must be same length.');
    end
    N = numel(hexA);
end

% Ensure output dir
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

% widths
Wbits = 128; Whex = Wbits/4;   % 32 hex digits for A,B
Cbits = 256; Chex = Cbits/4;   % 64 hex digits for GOLD

% ---------- Generate or normalize input vectors ----------
if isempty(hexA)
    % Generate random vectors + deterministic corner cases
    rng('shuffle');
    hexA = cell(N,1);
    hexB = cell(N,1);

    % Insert some corner cases in first few entries for robust testing
    cornerA = { repmat('0',1,Whex); ...                     % 0
                repmat('F',1,Whex); ...                     % all ones
                ['8000000000000000', repmat('0',1,16)]; ... % MSB set (signed negative if interpreted)
                '0000000000000000FFFFFFFFFFFFFFFF' };      % low half ones
    cornerB = { repmat('0',1,Whex); ...
                repmat('F',1,Whex); ...
                '00000000000000010000000000000000'; ...
                '0000000000000000FFFFFFFFFFFFFFFF' };

    % Add corner cases
    k = 1;
    for i=1:min(numel(cornerA), N)
        hexA{k} = pad_hex(cornerA{i}, Whex); hexB{k} = pad_hex(cornerB{i}, Whex); k=k+1;
    end

    % fill remaining with random 128-bit values (as hex)
    while k <= N
        % generate 128 bits in 32 hex digits by combining two random uint64 -> hex
        % use java SecureRandom via built-in rng; easier: randbytes (R2022b+). Fallback to rand.
        hi = randi([0, 2^32-1], 1, 2, 'uint32'); % two 32-bit words
        lo = randi([0, 2^32-1], 1, 2, 'uint32');
        % construct 128-bit as 4 words (msb first)
        words = [hi, lo]; % 4 uint32s
        hex_str = sprintf('%08X%08X%08X%08X', words(1), words(2), words(3), words(4));
        hexA{k} = hex_str;
        % new random for B
        hi2 = randi([0, 2^32-1], 1, 2, 'uint32');
        lo2 = randi([0, 2^32-1], 1, 2, 'uint32');
        words2 = [hi2, lo2];
        hexB{k} = sprintf('%08X%08X%08X%08X', words2(1), words2(2), words2(3), words2(4));
        k = k + 1;
    end
else
    % Provided hexA/hexB: normalize them
    for i=1:N
        hexA{i} = pad_hex(hexA{i}, Whex);
        hexB{i} = pad_hex(hexB{i}, Whex);
    end
end

% ---------- Compute golden products using Java BigInteger ----------
hexC = cell(N,1);
for i=1:N
    a = normalize_hex_for_bigint(hexA{i});
    b = normalize_hex_for_bigint(hexB{i});
    % BigInteger expects string base 16
    bigA = java.math.BigInteger(a, 16);
    bigB = java.math.BigInteger(b, 16);
    bigC = bigA.multiply(bigB);
    c_hex = char(bigC.toString(16)); % lower-case, no leading zeros
    % pad to Chex digits
    if length(c_hex) > Chex
        error('Product exceeds %d hex digits at vector %d', Chex, i);
    end
    hexC{i} = upper(sprintf(['%0', num2str(Chex), 's'], c_hex));
end

% ---------- Write files ----------
fileA = fullfile(outdir, 'testvecs_128b_base16_all.hex');
fileB = fullfile(outdir, 'testvecs_B_128b_base16_all.hex');
fileG = fullfile(outdir, 'golden_128b_base16_all.hex');

fidA = fopen(fileA,'w'); fidB = fopen(fileB,'w'); fidG = fopen(fileG,'w');
if fidA < 0 || fidB < 0 || fidG < 0
    error('Could not open output files for writing in %s', outdir);
end

for i=1:N
    fprintf(fidA, '%s\n', hexA{i});
    fprintf(fidB, '%s\n', hexB{i});
    fprintf(fidG, '%s\n', hexC{i});
end
fclose(fidA); fclose(fidB); fclose(fidG);
fprintf('Wrote %d vectors to directory "%s"\n', N, outdir);

% ---------- Validate files (quick) ----------
fprintf('Validating files...\n');
validate_hex_file(fileA, Whex);
validate_hex_file(fileB, Whex);
validate_hex_file(fileG, Chex);

fprintf('First 5 vectors (A, B, GOLD):\n');
for i=1:min(5,N)
    fprintf('%2d: A=%s  B=%s  GOLD=%s\n', i, hexA{i}, hexB{i}, hexC{i});
end

end

% ---------------- Helper functions ----------------
function s_out = pad_hex(s_in, target_hex_digits)
% remove whitespace, optional 0x, pad left with zeros, uppercase
s = strtrim(s_in);
s(s==' ') = [];
if isempty(s), s = '0'; end
if length(s) >= 2 && (strcmpi(s(1:2),'0x'))
    s = s(3:end);
end
% remove any non-hex just in case
s = regexprep(s, '[^0-9a-fA-F]', '');
% trim leading zeros then pad
if length(s) > target_hex_digits
    % if input is longer, error to avoid truncation
    error('Input hex "%s" longer than target width %d', s_in, target_hex_digits);
end
s_out = upper(sprintf(['%0', num2str(target_hex_digits), 's'], s));
end

function s_norm = normalize_hex_for_bigint(s, varargin)
% ensure string suitable for BigInteger constructor
if nargin==1
    s_norm = s;
else
    s_norm = pad_hex(s, varargin{1});
end
% remove leading zeros so BigInteger doesn't treat it as longer, but allow '0'
s_norm = regexprep(s_norm, '^0+(?!$)', '');
if isempty(s_norm), s_norm = '0'; end
end

function validate_hex_file(filepath, expected_hex_digits)
if ~exist(filepath,'file')
    error('File not found: %s', filepath);
end
fid = fopen(filepath,'r');
lineNo = 0; bad = 0;
while ~feof(fid)
    tline = fgetl(fid);
    lineNo = lineNo + 1;
    if isempty(tline)
        fprintf('  WARNING: empty line at %d\n', lineNo);
        bad = bad + 1;
        continue;
    end
    % remove whitespace
    s = regexprep(tline, '\s+', '');
    if length(s) ~= expected_hex_digits
        fprintf('  ERROR: line %d length %d (expected %d): "%s"\n', lineNo, length(s), expected_hex_digits, s);
        bad = bad + 1;
    end
    % ensure valid hex
    if ~all(ismember(lower(s), ['0':'9' 'a':'f']))
        fprintf('  ERROR: line %d contains non-hex characters: "%s"\n', lineNo, s);
        bad = bad + 1;
    end
end
fclose(fid);
if bad==0
    fprintf('  OK: %s (%d lines, each %d hex digits)\n', filepath, lineNo, expected_hex_digits);
else
    fprintf('  Found %d issues in %s (see messages)\n', bad, filepath);
end
end
