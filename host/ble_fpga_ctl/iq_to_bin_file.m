function iq_to_bin_file(a)
% bin file: copmlex, int16, i/q interleaved
% if a is a .wav file saved by sdr++, it should be saved in int16 format

bin_filename = 'iq.bin';

wav_file_input = 0;
if isstr(a) % a might be a filename
  [filepath, name, ext] = fileparts(a);
  if ~strcmpi(ext, '.wav')
    disp('The filename should be .wav. Saved via sdr++ in int16 format!');
    return;
  end
  [Y, FS] = audioread(a, 'native');
  data_type = class(Y);
  if ~strcmpi(data_type, 'int16')
    disp('The input file should be saved via sdr++ in int16 format!');
    return;
  end
  a = Y;
  clear Y;
  disp(['Sampling rate ' num2str(FS)]);
  bin_filename = [filepath '/' name '.bin'];
  wav_file_input = 1;
end

disp(bin_filename);

fid = fopen(bin_filename, 'w');
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

if wav_file_input == 0
  max_val = max(abs(a));
  scaling_factor = 30000/max_val;
  disp(['max ' num2str(max_val) ' scaling factor ' num2str(scaling_factor)]);
  a = int16(a.*scaling_factor);
end

fwrite(fid, a, 'int16');
fclose(fid);
