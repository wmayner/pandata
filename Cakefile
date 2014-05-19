{spawn, exec} = require 'child_process'
path          = require 'path'
wrench        = require 'wrench'
colors        = require 'colors'

# Config
srcDir = 'src'
libDir = 'lib'

# Colors
blue = '\x1b[34m'
red  = '\x1b[31m'
reset = '\x1b[0m'
colors.setTheme {
  verbose  : 'black'
, debug    : 'blue'
, error    : 'red'
, warn     : 'yellow'
, info     : 'green'
, emph     : 'inverse'
, underline: 'underline'
, data     : 'blue'
}

log = (message, styles, callback) ->
  if styles?
    for style in styles
      message = message[style]
  console.log message
  callback?()

execute = (cmd, options, callback) ->
  command = spawn cmd, options
  command.stdout.pipe process.stdout
  command.stderr.pipe process.stderr
  command.on 'exit', (status) ->
    callback?() if status is 0

docco = (callback) ->
  files = wrench.readdirSyncRecursive(srcDir)
  files = (path.join(srcDir,file) for file in files when /\.coffee$/.test file)
  files.push('Cakefile')
  console.log blue
  execute 'node_modules/docco-husky/bin/generate',
          files, ->
            log "└── Generated project documentation ", ['info']
            callback?()

# Compile coffee
coffee = (callback) ->
  # Print any errors in red
  console.log red
  # Compile app
  execute 'node_modules/coffee-script/bin/coffee',
          ['-c','-b', '-o', libDir, srcDir]
          log "├── Compiled .coffee files in #{srcDir} to #{libDir}",
            ['info'],
            (callback if callback?)

build = (callback) ->
  log ' Building project... ', ['info', 'emph']
  coffee ->
    # docco ->
    log '\n ...project built. ', ['info', 'emph'],
      (callback if callback?)

task 'docs', 'Generate annotated source code with Docco', ->
  docco -> console.log "Generated annotaed source code with Docco."

task 'build', 'Build the project', ->
  build()
