function iq_to_bin_file(a)
% bin file: copmlex, int16, i/q interleaved
fid = fopen('iq.bin', 'w');
if fid == -1
    disp('fopen failed!');
    return;
end

if iscomplex(a)
  a = [real(a(:)), imag(a(:))];
end

[~, num_col] = size(a);

if num_col == 2
  a = a.';
end

a = a(:);
max_val = max(abs(a));
scaling_factor = 30000/max_val;
disp(['max ' num2str(max_val) ' scaling factor ' num2str(scaling_factor)]);
a = int16(a.*scaling_factor);

fwrite(fid, a, 'int16');
fclose(fid);
