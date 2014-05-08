module.exports = (grunt) ->
  "use strict"

  packageJSON = grunt.file.readJSON 'package.json'

  grunt.initConfig({
    pkg: packageJSON,

    copy:
      manifest:
        src: 'src/manifest.json',
        dest: 'build/manifest.json',
        options:
          process: (content) ->
            content.replace '$version', packageJSON.version
      icons:
        files: [{
          expand: true,
          cwd: 'src/',
          src: 'icon*.png',
          dest: 'build'
        }]

    sass:
      options:
        style: 'compressed',
        precision: 4
    # Source maps require SASS 3.3.0
    # sourcemap: true
      dist:
        files: [{
          expand: true,
          cwd: 'src/',
          src: '**/*.sass',
          dest: 'build',
          ext: '.css'
        }]

    coffee:
#      options:
#        sourceMap: true
      dist:
        files: [{
          expand: true,
          cwd: 'src/',
          src: '**/*.coffee',
          dest: 'build',
          ext: '.js'
        }]

    jade:
      dist:
        files: [{
          expand: true,
          cwd: 'src/',
          src: '**/*.jade',
          dest: 'build',
          ext: '.html'
        }]

    autoprefixer:
      options: ['last 2 versions']
      dist:
        src: 'build/*.css'

    zip:
      dist:
        cwd: 'build/',
        src: 'build/**/*',
        dest: 'dist/key-jump-' + packageJSON.version + '.zip'

    watch:
      copy:
        files: ['src/manifest.json', 'src/icon*.png'],
        tasks: 'copy'
      sass:
        files: 'src/*.sass',
        tasks: 'sass'
      coffee:
        files: 'src/*.coffee',
        tasks: 'coffee'
      jade:
        files: 'src/*.jade',
        tasks: 'jade'
      autoprefixer:
        files: 'build/*.css',
        tasks: 'autoprefixer'
  })

  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-autoprefixer'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-zip'

  grunt.registerTask 'default', ['copy', 'sass', 'coffee', 'jade', 'autoprefixer', 'zip']
  grunt.registerTask 'dist', 'default'
  grunt.registerTask 'd', 'dist'
  grunt.registerTask 'w', 'watch'
