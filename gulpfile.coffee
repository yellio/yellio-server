gulp       = require 'gulp'
coffee     = require 'gulp-coffee-es6'

gulp.task 'compile', ->
  gulp.src './src/**/*.coffee'
    .pipe coffee bare: yes
    .pipe gulp.dest './lib/'

gulp.task 'watch', ->
  gulp.watch './src/**/*.coffee', ['compile']

gulp.task 'default', ['compile', 'watch']
