%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %
%   Copyright (C) 2010 William Mallard                                        %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dsp48e_bram_vacc_init (blk, varargin)
% Initialize and configure a simple_bram_vacc block.
%
% dsp48e_bram_vacc_init(blk, varargin)
%
% blk = The block to configure.
% varargin = {'varname', 'value', ...} pairs.
%
% Valid varnames:
% * vec_len
% * arith_type
% * bin_pt_in
% * n_bits_out

% Set default vararg values.
defaults = { ...
  'vec_len', 8, ...
  'arith_type', 'Unsigned', ...
  'bin_pt_in', 31, ...
  'n_bits_out', 32, ...
};

% Skip init script if mask state has not changed.
if same_state(blk, 'defaults', defaults, varargin{:}),
  return
end

% Verify that this is the right mask for the block.
check_mask_type(blk, 'dsp48e_bram_vacc');

% Disable link if state changes from default.
munge_block(blk, varargin{:});

% Retrieve input fields.
vec_len = get_var('vec_len', 'defaults', defaults, varargin{:});
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
bin_pt_in = get_var('bin_pt_in', 'defaults', defaults, varargin{:});
n_bits_out = get_var('n_bits_out', 'defaults', defaults, varargin{:});

% Validate input fields.

if (vec_len < 6),
  errordlg([blk, ': Vector length must be greater than 5.']);
  return
end

if (bin_pt_in < 0),
  errordlg([blk, ': Binary point must be non-negative.']);
  return
end

if (n_bits_out < 1),
  errordlg([blk, ': Bit width must be greater than 0.']);
  return
end

if (n_bits_out > 48),
  errordlg([blk, ': Output bit width cannot exceed 48.']);
  return
end

% Update sub-block parameters.
set_param([blk, '/convert'], 'bin_pt_in', num2str(bin_pt_in));
set_param([blk, '/convert'], 'n_bits_out', num2str(n_bits_out));
set_param([blk, '/convert'], 'bin_pt_out', num2str( bin_pt_in - (48 - n_bits_out) ));
set_param([blk, '/convert'], 'quantization', 'Round  (biased: Up)');
set_param([blk, '/convert'], 'overflow', 'Wrap');
set_param([blk, '/convert'], 'latency', '2');

% Save block state to stop repeated init script runs.
save_state(blk, 'defaults', defaults, varargin{:});

