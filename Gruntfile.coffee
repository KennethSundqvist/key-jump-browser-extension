module.exports = (grunt) ->

  packageJSON = grunt.file.readJSON 'package.json'

  grunt.initConfig({
    pkg: packageJSON,

    copy:
      manifest:
        src: 'src/manifest.json',
        dest: 'dist/manifest.json',
        options:
          process: (content) ->
            content.replace '$version', packageJSON.version

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
          dest: 'dist',
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
          dest: 'dist',
          ext: '.js'
        }]

    autoprefixer:
      options: ['last 2 versions']
      dist:
        src: 'dist/*.css'

    watch:
      copy:
        files: 'src/manifest.json',
        tasks: 'copy'
      sass:
        files: 'src/*.sass',
        tasks: 'sass'
      coffee:
        files: 'src/*.coffee',
        tasks: 'coffee'
      autoprefixer:
        files: 'dist/*.css',
        tasks: 'autoprefixer'
  })

  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-autoprefixer'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['copy', 'sass', 'coffee', 'autoprefixer']
  grunt.registerTask 'dist', 'default'
  grunt.registerTask 'd', 'dist'
  grunt.registerTask 'w', 'watch'
