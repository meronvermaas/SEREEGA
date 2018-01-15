% arm_get_class_interacting(numSources, order, numInteractions, epochs, amplitude, varargin)
%
%       Uses an autoregressive model to generate a given number of source
%       activation signals with the given number of interactions between
%       them.
%
%       The activations are generated and returned as data classes.
%
% In:
%       numSources - the number of autoregressive source activations to
%                    compute
%       order - the order of the autoregressive model, i.e., the number of
%               lags
%       interactions - the number of interactions to be modelled between th
%                      the sources. random interactions will be selected.
%                      alternatively, this argument can be a vector of
%                      indices in the numSources-by-numSources matrix
%                      indicating which interactions are modelled. see
%                      the plotInteractions argument to visualise this
%                      matrix.
%       epochs - single epoch configuration struct containing at least
%                sampling rate in Hz (field name 'srate'), epoch length in ms
%                 ('length'), and the total number of epochs ('n')
%       amplitude - the amplitude of the resulting signals
%
% Optional (key-value pairs):
%       amplitudeDv - the amplitude deviation of the resulting signals
%       amplitudeSlope - the amplitude slope of the resulting signals
%       probability - the probability of the resulting signals
%       probabilitySlope - the probability slope of the resulting signals
%
% Out:  
%       signal - row array containing the data classes
%
% Usage example:
%       The following produces an EEGLAB dataset with 2 autoregressive
%       source activations, one influencing the other, 10 cm apart, and 62
%       pink noise sources.
%       >> epochs = struct('n', 10, 'srate', 1000, 'length', 1000);
%       >> lf = lf_generate_fromnyhead('montage', 'BioSemi64');
%       >> arm = arm_get_class_interacting(2, 10, 1, epochs, 1);
%       >> armsourcelocs = lf_get_source_spaced(lf, 2, 100);
%       >> armcomps = struct('source', num2cell(armsourcelocs));
%       >> armcomps = utl_add_signal_tocomponent(arm, armcomps);
%       >> noise = struct('color', 'pink', 'amplitude', 1);
%       >> noise = utl_check_class(noise, 'type', 'noise');
%       >> noisesourcelocs = lf_get_source_spaced(lf, 62, 25);
%       >> noisecomps = struct('source', num2cell(noisesourcelocs));
%       >> noisecomps = utl_add_signal_tocomponent(noise, noisecomps);
%       >> components  = utl_check_component([armcomps, noisecomps], lf);
%       >> data = generate_scalpdata(components, lf, epochs);
%       >> EEG = utl_create_eeglabdataset(data, epochs, lf);
%       >> EEG = utl_add_icaweights_toeeglabdataset(EEG, components, lf);
% 
%                    Copyright 2018 Laurens R Krol
%                    Team PhyPA, Biological Psychology and Neuroergonomics,
%                    Berlin Institute of Technology

% 2018-01-15 First version

% This file is part of Simulating Event-Related EEG Activity (SEREEGA).

% SEREEGA is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% SEREEGA is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with SEREEGA.  If not, see <http://www.gnu.org/licenses/>.

function arm = arm_get_class_interacting(numSources, order, interactions, epochs, amplitude, varargin)

% parsing input
p = inputParser;

addRequired(p, 'numSources', @isnumeric);
addRequired(p, 'order', @isnumeric);
addRequired(p, 'numInteractions', @isnumeric);
addRequired(p, 'epochs', @isstruct);
addRequired(p, 'amplitude', @isnumeric);

addParameter(p, 'amplitudeDv', 0, @isnumeric);
addParameter(p, 'amplitudeSlope', 0, @isnumeric);
addParameter(p, 'probability', 1, @isnumeric);
addParameter(p, 'probabilitySlope', 0, @isnumeric);
addParameter(p, 'plotInteractions', 0, @isnumeric);

parse(p, numSources, order, interactions, epochs, amplitude, varargin{:})

numSources = p.Results.numSources;
order = p.Results.order;
interactions = p.Results.numInteractions;
amplitude = p.Results.amplitude;
amplitudeDv = p.Results.amplitudeDv;
amplitudeSlope = p.Results.amplitudeSlope;
probability = p.Results.probability;
probabilitySlope = p.Results.probabilitySlope;
plotInteractions = p.Results.plotInteractions;

samples = floor(epochs.srate * epochs.length/1000);

% getting coefficient tensor
[~, tensor, ~, ~, sigma] = arm_generate_signal(numSources, samples, order, interactions);

% simulating epochs
data = zeros(numSources, samples, epochs.n);
for e = 1:epochs.n
    data(:,:,e) = arm_generate_signal(numSources, samples, order, interactions, sigma, tensor);
end

% delegating signals to data classes
for n = 1:numSources
    arm(n) = struct('type', 'data', ...
                    'data', squeeze(data(n,:,:))', ...
                    'index', {{'e', ':'}}, ...
                    'amplitude', amplitude, ...
                    'amplitudeDv', amplitudeDv, ...
                    'amplitudeSlope', amplitudeSlope, ...
                    'probability', probability, ...
                    'probabilitySlope', probabilitySlope);
end

for n = 1:numSources
    arm(n) = utl_check_class(arm(n));
end

if plotInteractions
    tensor = reshape(tensor, numSources, numSources, order);
    figure; imagesc(mean(abs(tensor),3) ~= 0);
end

end