function generate_hex_vectors(N, W, outdir, seed)
% generate_hex_vectors(N, W, outdir, seed)
% Generates N random test vectors of width W bits (default W=128),
% writes files into outdir:
%   testvecs_128b_base16_all.hex   (A vectors, one hex per line, width W/4 chars)
%   testvecs_B_128b_base16_all.hex (B vectors)
%   golden_128b_base16_all.hex     (GOLD vectors, one hex per line, width 2*W/4 chars)
%
% Example:
%   generate_hex_vectors(50, 128, 'results', 12345)

    if nargin < 1 || isempty(N), N = 50; end
    if nargin < 2 || isempty(W), W = 128; end
    if nargin < 3 || isempty(outdir), outdir = 'results'; end
    if nargin < 4 || isempty(seed), seed = sum(100*clock); end

    % Sanity checks
    if mod(W,8) ~= 0
        error('W must be a multiple of 8 bits.');
    end

    bytesA = W/8;
    hexCharsA = W/4;        % number of hex characters for A
    hexCharsC = 2 * hexCharsA; % number of hex chars for product

    % create outdir
    if ~exist(outdir,'dir'), mkdir(outdir); end

    % Files
    fileA = fullfile(outdir, sprintf('testvecs_%db_base16_all.hex', W));
    fileB = fullfile(outdir, sprintf('testvecs_B_%db_base16_all.hex', W));
    fileG = fullfile(outdir, sprintf('golden_%db_base16_all.hex', W));

    % open files
    fa = fopen(fileA,'w');
    fb = fopen(fileB,'w');
    fg = fopen(fileG,'w');
    if fa < 0 || fb < 0 || fg < 0
        error('Cannot open output files. Check directory permissions.');
    end

    % seed MATLAB RNG (used only to produce the byte vectors)
    rng(seed,'twister');

    for i = 1:N
        % generate random bytes (big-endian MSB first)
        bytes_a = uint8(randi([0,255], 1, bytesA));
        bytes_b = uint8(randi([0,255], 1, bytesA));

        % convert to hex string (msb first). sprintf returns lowercase by default.
        a_hex = lower(sprintf('%02x', bytes_a)); % length = bytesA*2
        b_hex = lower(sprintf('%02x', bytes_b));

        % remove any leading spaces (sprintf shouldn't add any) and ensure length
        if length(a_hex) ~= hexCharsA || length(b_hex) ~= hexCharsA
            error('Unexpected hex string length (internal).');
        end

        % create java BigInteger from hex (base 16)
        % note: java.math.BigInteger accepts a hex string without 0x prefix
        a_big = java.math.BigInteger(a_hex, 16);
        b_big = java.math.BigInteger(b_hex, 16);

        % compute product
        c_big = a_big.multiply(b_big);

        % convert product to hex string
        c_hex = char(c_big.toString(16));    % this gives hex without leading zeros

        % pad a_hex, b_hex, c_hex with leading zeros to fixed widths
        a_hex_p = padLeft(a_hex, hexCharsA);
        b_hex_p = padLeft(b_hex, hexCharsA);
        c_hex_p = padLeft(c_hex, hexCharsC);

        % write as uppercase (optional) — your TB accepts either case usually
        fprintf(fa, '%s\n', upper(a_hex_p));
        fprintf(fb, '%s\n', upper(b_hex_p));
        fprintf(fg, '%s\n', upper(c_hex_p));
    end

    fclose(fa); fclose(fb); fclose(fg);

    fprintf('Wrote %d vectors to:\n  %s\n  %s\n  %s\n', N, fileA, fileB, fileG);
end

function s2 = padLeft(s, totalLen)
    % padLeft: pad string s on left with '0' to reach totalLen characters.
    if isempty(s)
        s = '0';
    end
    s = char(s);
    % remove any leading '+' sign that java BigInteger might produce (shouldn't)
    if s(1) == '+'
        s = s(2:end);
    end
    % to lower-case just in case
    s = lower(s);
    if length(s) > totalLen
        % if number too large to fit expected width, that's an error
        error('Value exceeded expected field width: %d > %d', length(s), totalLen);
    end
    s2 = [repmat('0', 1, totalLen - length(s)), s];
end