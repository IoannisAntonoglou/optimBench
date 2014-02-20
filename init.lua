require 'torch'
require 'sys'

optimbench = {}

-- benchmarking

torch.include('optimbench', 'utils.lua')
torch.include('optimbench', 'numintegr.lua')

torch.include('optimbench', 'prototypes_noise.lua')
torch.include('optimbench', 'prototypes_functions.lua')
torch.include('optimbench', 'non_stationarity.lua')
torch.include('optimbench', 'multivariate_functions.lua')
torch.include('optimbench', 'algorithm_wrapper.lua')
torch.include('optimbench', 'noise_integration_prototypes.lua')
torch.include('optimbench', 'torchExtensions.lua')
torch.include('optimbench', 'functions_factory.lua')

torch.include('optimbench', 'experiment_entry.lua')
torch.include('optimbench', 'function_definitions.lua')
torch.include('optimbench', 'algorithms_list.lua')
torch.include('optimbench', 'experiment.lua')
--torch.include('optimx', 'example_code.lua')
