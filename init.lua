require 'torch'
require 'sys'

optimx = {}

-- benchmarking

torch.include('optimx', 'utils.lua')
torch.include('optimx', 'numintegr.lua')

torch.include('optimx', 'prototypes_noise.lua')
torch.include('optimx', 'prototypes_functions.lua')
torch.include('optimx', 'non_stationarity.lua')
torch.include('optimx', 'multivariate_functions.lua')
torch.include('optimx', 'algorithm_wrapper.lua')
torch.include('optimx', 'noise_integration_prototypes.lua')
torch.include('optimx', 'torchExtensions.lua')
torch.include('optimx', 'functions_factory.lua')

torch.include('optimx', 'experiment_entry.lua')
torch.include('optimx', 'function_definitions.lua')
torch.include('optimx', 'algorithms_list.lua')
torch.include('optimx', 'experiment.lua')
--torch.include('optimx', 'example_code.lua')
