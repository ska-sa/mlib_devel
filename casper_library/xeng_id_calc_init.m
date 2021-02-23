function xeng_id_calc_init(blk, varargin)
%function to generate block outputing xengine id

defaults = {'xeng_id', '0',...
            'n_bits_xengs_per_fpga','2',...
            'n_bits_xengs','2'};

if same_state(blk, 'defaults', defaults, varargin{:}), return, end
munge_block(blk, varargin{:});
delete_lines(blk);

xeng_id = get_var('xeng_id', 'defaults', defaults, varargin{:});
n_bits_xengs_per_fpga = get_var('n_bits_xengs_per_fpga', 'defaults', defaults, varargin{:});
n_bits_xengs = get_var('n_bits_xengs', 'defaults', defaults, varargin{:});

%handle case if we have more than one fpga in the system:
if (n_bits_xengs > n_bits_xengs_per_fpga)

	reuse_block(blk, 'In1', 'built-in/Inport');
	set_param([blk,'/In1'], ...
		'Port', sprintf('1'), ...
		'Position', sprintf('[20 23 50 37]'), ...
		'Tag', sprintf(''));

	reuse_block(blk, 'Slice11', 'xbsIndex_r4/Slice');
	set_param([blk,'/Slice11'], ...
		'nbits', num2str(n_bits_xengs - n_bits_xengs_per_fpga), ...
		'mode', sprintf('Lower Bit Location + Width'), ...
		'Position', sprintf('[95 22 120 38]'), ...
		'Tag', sprintf(''));

	reuse_block(blk, 'Constant10', 'xbsIndex_r4/Constant');
	set_param([blk,'/Constant10'], ...
		'const', num2str(xeng_id), ...
		'arith_type', sprintf('Unsigned'), ...
		'n_bits', num2str(n_bits_xengs_per_fpga), ...
		'bin_pt', sprintf('0'), ...
		'explicit_period', sprintf('on'), ...
		'Position', sprintf('[100 39 115 51]'), ...
		'Tag', sprintf(''));

	reuse_block(blk, 'Concat6', 'xbsIndex_r4/Concat');
	set_param([blk,'/Concat6'], ...
		'Position', sprintf('[175 22 210 53]'), ...
		'Tag', sprintf(''));

	reuse_block(blk, 'Out1', 'built-in/Outport');
	set_param([blk,'/Out1'], ...
		'Port', sprintf('1'), ...
		'Position', sprintf('[265 33 295 47]'), ...
		'Tag', sprintf(''));

	add_line(blk,'In1/1','Slice11/1', 'autorouting', 'on');
	add_line(blk,'Slice11/1','Concat6/1', 'autorouting', 'on');
	add_line(blk,'Constant10/1','Concat6/2', 'autorouting', 'on');
	add_line(blk,'Concat6/1','Out1/1', 'autorouting', 'on');
else
	reuse_block(blk, 'In1', 'built-in/Inport');
	set_param([blk,'/In1'], ...
		'Port', sprintf('1'), ...
		'Position', sprintf('[20 23 50 37]'), ...
		'Tag', sprintf(''));

    reuse_block(blk, 'Constant10', 'xbsIndex_r4/Constant');
	set_param([blk,'/Constant10'], ...
		'const', num2str(xeng_id), ...
		'arith_type', sprintf('Unsigned'), ...
		'n_bits', num2str(n_bits_xengs_per_fpga), ...
		'bin_pt', sprintf('0'), ...
		'explicit_period', sprintf('on'), ...
		'Position', sprintf('[100 39 115 51]'), ...
		'Tag', sprintf(''));

	reuse_block(blk, 'Out1', 'built-in/Outport');
	set_param([blk,'/Out1'], ...
		'Port', sprintf('1'), ...
		'Position', sprintf('[265 33 295 47]'), ...
		'Tag', sprintf(''));

    add_line(blk,'Constant10/1','Out1/1', 'autorouting', 'on');
    blocks = get_param(blk, 'Blocks');
    if (sum(ismember(blocks,'Concat6'))>0), delete_block([blk,'/Concat6']), end
    if (sum(ismember(blocks,'Slice11'))>0), delete_block([blk,'/Slice11']), end
end

save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

end % xeng_id_calc.m

