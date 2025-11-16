function generate_hrkm_vectors_fixed()
% Generates random 128-bit input vector file and golden 128-bit product file.
% Avoids double-precision by using hex strings and java.math.BigInteger.

    % === PARAMETERS ===
    W = 128;                % bit-width
    NUM_VECS = 200;         % number of vectors to generate
    % Filenames (match names used by your testbench)
    vec_file  = 'results/testvecs_128b_base16_v1.hex';
    gold_file = 'results/golden_128b_base16_v1.hex';

    % Make results folder if it doesn't exist
    if ~exist('results','dir')
        mkdir('results');
    end

    fh_vec = fopen(vec_file,'w');
    fh_gold = fopen(gold_file,'w');
    if fh_vec==-1 || fh_gold==-1
        error('Unable to open output files. Check permissions and paths.');
    end

    hex_digits = '0123456789abcdef';

    for i=1:NUM_VECS
        % --- create random 128-bit hex strings (32 hex chars) ---
        A_hex = random_hex_string(32, hex_digits);
        B_hex = random_hex_string(32, hex_digits);

        % Ensure no leading minus by forcing uppercase/lowercase consistent (we use lowercase)
        A_hex = lower(A_hex);
        B_hex = lower(B_hex);

        % Convert hex strings to java.math.BigInteger (base 16)
        A_big = java.math.BigInteger(A_hex, 16);
        B_big = java.math.BigInteger(B_hex, 16);

        % Multiply using BigInteger (exact, arbitrary precision)
        C_big = A_big.multiply(B_big);

        % Convert product to hex string and pad to 64 hex characters (128*2 = 256 bits? careful)
        % Note: product of two 128-bit numbers fits into 256 bits => 64 hex chars
        C_hex = char(C_big.toString(16));
        C_hex = lower(C_hex);
        C_hex = pad(C_hex, 64, 'left', '0');  % pad to 64 hex chars

        % Pad A and B to 32 hex chars (just in case random produced leading zeros)
        A_hex = pad(A_hex, 32, 'left', '0');
        B_hex = pad(B_hex, 32, 'left', '0');

        % Write input vector file: "A_hex B_hex" (one vector per line)
        fprintf(fh_vec, '%s %s\n', A_hex, B_hex);

        % Write golden output file: "C_hex" (one product per line)
        fprintf(fh_gold, '%s\n', C_hex);
    end

    fclose(fh_vec);
    fclose(fh_gold);

    fprintf('Generated files:\n  %s\n  %s\n', vec_file, gold_file);
end

function s = random_hex_string(len, hex_digits)
    % Create 'len' hex characters using MATLAB's RNG
    % We avoid building big integers; just create a hex string.
    idx = randi(numel(hex_digits), [1 len]);
    s = hex_digits(idx);
end