from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need
# fine tuning.
buildOptions = dict(include_files = ['../plsql/', '../sql/', '../setup.sql'])

# Let us grab platform to set specific settings

executables = [
    Executable('npg', 'Console')
]

setup(name='npg',
      version = '0.0.1',
      description = 'CLI for PL/SQL NPG packages.',
      options = dict(build_exe = buildOptions),
      executables = executables)
