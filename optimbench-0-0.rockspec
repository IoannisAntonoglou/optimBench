package = 'optimbench'
version = '0-0'

source = {
   url = 'git://github.com/IoannisAntonoglou/optimBench.git',
   branch = 'master'
}

description = {
  summary = "A benchmark testbed for optimisation algorithms",
  homepage = "https://github.com/IoannisAntonoglou/optimBench.git"
}

dependencies = { 'torch >= 7.0', 'optim'}

build = {
   type = "command",
   build_command = [[
cmake -E make_directory build;
cd build;
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(LUA_BINDIR)/.." -DCMAKE_INSTALL_PREFIX="$(PREFIX)"; 
$(MAKE)
   ]],
   install_command = "cd build && $(MAKE) install"
}