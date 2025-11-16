function hrkm_run_all()
% HRKM_RUN_ALL  Driver to run HRKM tests, timing, verification, and export test vectors.
% Produces CSV summary in results/ and hex test vector files for RTL testbenches.

% Config
bits_list = [128, 256, 512];       % widths to test
base_bits_list = [8, 16, 32];      % recursion cutoff values to sweep
num_vectors = 20;                  % number of random test vectors per config
rng('shuffle');

outdir = fullfile(pwd, 'results');
if ~exist(outdir, 'dir'), mkdir(outdir); end

summary_rows = {};
row_idx = 1;
fprintf('HRKM functional tests starting — results will be saved to %s\n', outdir);

for N = bits_list
    for base_bits = base_bits_list
        fprintf('\n--- Testing N=%d bits, base_bits=%d ---\n', N, base_bits);
        for v = 1:num_vectors
            % generate random big integers
            A = randomBigInt(N);
            B = randomBigInt(N);
            % time karat2N
            tstart = tic;
            C_karat = karat2N(A, B, N, base_bits);
            t_k = toc(tstart);
            % direct multiply (golden)
            tstart = tic;
            C_direct = A.multiply(B);
            t_d = toc(tstart);
            % verify
            correct = C_karat.equals(C_direct);
            if ~correct
                warning('Mismatch for N=%d base=%d vector %d', N, base_bits, v);
            end
            % export test vector (hex) — store A, B, C_direct
            vecname = sprintf('testvecs_%db_base%d_v%d.hex', N, base_bits, v);
            exportTestVectorHex(fullfile(outdir, vecname), A, B, C_direct, N);
            % collect summary row
            summary_rows{row_idx,1} = N;
            summary_rows{row_idx,2} = base_bits;
            summary_rows{row_idx,3} = v;
            summary_rows{row_idx,4} = t_k;
            summary_rows{row_idx,5} = t_d;
            summary_rows{row_idx,6} = correct;
            row_idx = row_idx + 1;
            fprintf('N=%d base=%d v=%d: karat_time=%.6f s, direct=%.6f s, ok=%d\n', ...
                N, base_bits, v, t_k, t_d, correct);
        end
    end
end

% write CSV
csvfile = fullfile(outdir, 'summary.csv');
fid = fopen(csvfile, 'w');
fprintf(fid, 'N,base_bits,vector_idx,karat_time_s,direct_time_s,correct\n');
for i = 1:size(summary_rows,1)
    fprintf(fid, '%d,%d,%d,%.9f,%.9f,%d\n', summary_rows{i,1}, summary_rows{i,2}, summary_rows{i,3}, ...
        summary_rows{i,4}, summary_rows{i,5}, summary_rows{i,6});
end
fclose(fid);

fprintf('\nAll done. Summary CSV: %s\n', csvfile);
end