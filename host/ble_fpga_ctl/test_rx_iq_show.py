# Author: Xianjun Jiao <putaoshu@msn.com>
# SPDX-FileCopyrightText: 2024 Xianjun Jiao
# SPDX-License-Identifier: Apache-2.0 license

from datetime import datetime
from fileinput import filename

import numpy as np
# import matplotlib
# matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
# from matplotlib.colors import LogNorm

import argparse
import sys
import os
import wave

def water_fall(iq, fft_size, num_sample_feed_to_fft, sample_resolution):
  num_col = int((len(iq) - num_sample_feed_to_fft + 1) // sample_resolution)
  a = np.zeros((fft_size, num_col))

  for i in range(num_col):
    sp = i * sample_resolution
    ep = sp + num_sample_feed_to_fft
    a[:, i] = np.abs(np.fft.fft(iq[sp:ep], fft_size)) ** 2

  fft_size_half = fft_size // 2
  a = np.concatenate([a[fft_size_half:, :], a[:fft_size_half, :]], axis=0)

  return a

if __name__ == "__main__":
  freq_hz = np.uint64(2402e6)
  duration_ms = int(100)
  sampling_rate_hz = int(8e6)

  fft_size = int(128)
  num_sample_feed_to_fft = int(64)
  sample_resolution = int(2)
  
  parser = argparse.ArgumentParser(
    description="Waterfall spectrum analyzer"
  )

  parser.add_argument("-f", "--filename", type=str, default="", help="IQ file to be analyzed. .wav or .bin. Has to be int16 with dual channels. If not provided, will do on board capture and scp to local")
  parser.add_argument("-n", "--freq_hz", type=int, default=freq_hz, help="Input frequency in Hz (default: "+str(freq_hz))
  parser.add_argument("-q", "--duration_ms", type=int, default=duration_ms, help="Input duration in ms (default: "+str(duration_ms))
  parser.add_argument("-s", "--sampling_rate_hz", type=int, default=sampling_rate_hz, help="Input sampling rate in Hz (default: "+str(sampling_rate_hz))
  parser.add_argument("-N", "--fft_size", type=int, default=fft_size, help="Input FFT size (default: "+str(fft_size))
  parser.add_argument("-E", "--num_sample_feed_to_fft", type=int, default=num_sample_feed_to_fft, help="Input number of samples or noverlap for specgram fed to FFT (default: "+str(num_sample_feed_to_fft))
  parser.add_argument("-R", "--sample_resolution", type=int, default=sample_resolution, help="Input sample resolution (default: "+str(sample_resolution))
  parser.add_argument("-S", "--skip_waterfall", type=int, default=0, help="Skip waterfall plot if set to 1 (default: 0)")

  args = parser.parse_args()

  if args.freq_hz:
    freq_hz = np.uint64(args.freq_hz)
  
  if args.duration_ms:
    duration_ms = int(args.duration_ms)
  
  if args.sampling_rate_hz:
    sampling_rate_hz = int(args.sampling_rate_hz)

  if args.fft_size:
    fft_size = int(args.fft_size)
  
  if args.num_sample_feed_to_fft:
    num_sample_feed_to_fft = int(args.num_sample_feed_to_fft)
  
  if args.sample_resolution:
    sample_resolution = int(args.sample_resolution)

  if args.filename:
    rx_iq_filename = args.filename
  else:
    rx_iq_filename = 'rx_iq_'+str(freq_hz)+'Hz_'+str(sampling_rate_hz)+'sps.bin'

    ssh_cmd  = 'ssh root@10.10.10.10 ./btle_ll -q '+str(duration_ms)+' -o 1 -n '+str(freq_hz)
    print(ssh_cmd)
    status = os.system(ssh_cmd)
    if status != 0:
      print('SSH command failed')
      sys.exit(1)

    scp_cmd = 'scp root@10.10.10.10:' + rx_iq_filename + ' ./'
    status = os.system(scp_cmd)
    if status != 0:
        print('SCP command failed')
        sys.exit(1)

  print(rx_iq_filename)

  # name_without_ext = rx_iq_filename.rsplit('.', 1)[0]
  # date_time_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
  # new_filename = f"{name_without_ext}_{date_time_str}.bin"
  # os.rename(rx_iq_filename, new_filename)
  # print('Saved as ', new_filename)

  if rx_iq_filename.lower().endswith(".wav"):
    # Open WAV file
    with wave.open(rx_iq_filename, "rb") as wf:
      num_channels = wf.getnchannels()
      sample_width = wf.getsampwidth()
      num_frames = wf.getnframes()
      sampling_rate_hz = wf.getframerate()
      print(f"WAV file info: {num_channels} channels, {sample_width * 8}-bit samples, {num_frames} frames, {sampling_rate_hz} Hz")

      # Check dual channel
      if num_channels != 2:
        raise ValueError(
            f"WAV file must have 2 channels, got {num_channels}"
        )

      # Check int16 format (2 bytes/sample)
      if sample_width != 2:
        raise ValueError(
            f"WAV file must be int16, got {sample_width * 8}-bit samples"
        )

      # Read raw samples
      raw_data = wf.readframes(num_frames)

    # Convert to int16 and reshape to (N, 2)
    iq_samples = np.frombuffer(raw_data, dtype=np.int16).reshape(-1, 2)

    rx_i = iq_samples[:, 0]
    rx_q = iq_samples[:, 1]

  elif rx_iq_filename.lower().endswith(".bin"):
    with open(rx_iq_filename, mode="rb") as file:
      my_bytes = file.read()

    rx_iq = np.frombuffer(my_bytes, dtype=np.int16)
    rx_i = rx_iq[0::2]
    rx_q = rx_iq[1::2]

  rx_complex = rx_i + 1j * rx_q  # the sampling rate is alraedy iq sampling rate

  if len(rx_i) > 4000001:
    print('Decide the start/end idx. Close figure and input ...')

    plt.plot(np.absolute(rx_complex), 'b', label='Abs')
    # plt.plot(rx_i, 'b', label='I')
    # plt.plot(rx_q, 'r', label='Q')
    plt.legend(loc='upper right')
    plt.grid(True)
    plt.title('Decide the start/end idx. Close figure and input ...')
    plt.show()

    start_index = int(input('Enter the start index for processing: '))
    end_index = int(input('Enter the end index for processing: '))
    rx_i = rx_i[start_index:end_index]
    rx_q = rx_q[start_index:end_index]
    rx_complex = rx_i + 1j * rx_q  # the sampling rate is alraedy iq sampling rate

    # close the figure after user input
    plt.close()

    # Interleave as I,Q,I,Q,...
    iq_interleaved = np.empty(rx_i.size * 2, dtype=np.int16)
    iq_interleaved[0::2] = rx_i
    iq_interleaved[1::2] = rx_q
    iq_interleaved.tofile("iq_samples_sub.bin")
    print('Saved the sub IQ samples to iq_samples_sub.bin')

  fig_iq = plt.figure(1)
  fig_iq.clf()

  td_abs = fig_iq.add_subplot(111)
  td_abs.set_title('IQ plot')
  td_abs.set_xlabel("sample idx")
  td_abs.set_ylabel("I/Q")
  td_abs.plot(rx_i, 'b', label='I')
  td_abs.plot(rx_q, 'r', label='Q')
  td_abs.legend(loc='upper right')
  td_abs.grid(True)
  
  fig_iq.canvas.flush_events()

  if not args.skip_waterfall:
    # a = water_fall(rx_complex, fft_size=fft_size, num_sample_feed_to_fft=num_sample_feed_to_fft, sample_resolution=sample_resolution)

    time_resolution_us = (sample_resolution*(1/sampling_rate_hz))*1e6
    # print(a.shape)
    # print(a[:, 0:10])

    fig_waterfall = plt.figure(0)
    fig_waterfall.clf()

    # vmin = np.percentile(a,  0.3)
    # vmax = np.percentile(a, 99.7)

    waterfall = fig_waterfall.add_subplot(111)
    # Pxx, freqs, bins, im = waterfall.specgram(rx_complex, NFFT=fft_size, Fs=sampling_rate_hz, noverlap=512, scale='dB', mode='psd')
    Pxx, freqs, bins, im = waterfall.specgram(rx_complex, NFFT=fft_size, Fs=sampling_rate_hz, noverlap=num_sample_feed_to_fft, scale='dB', mode='psd')
    waterfall.set_title('Spectrogram')
    waterfall.set_xlabel("Time (s)")
    waterfall.set_ylabel("Frequency (Hz)")

    # waterfall_shw = waterfall.imshow(a, vmin=vmin, vmax=vmax, aspect='auto', origin='lower', extent=[0, a.shape[1]*time_resolution_us, -sampling_rate_hz/2, sampling_rate_hz/2])
    # plt.colorbar(waterfall_shw)
    fig_waterfall.canvas.flush_events()

    plt.show()
