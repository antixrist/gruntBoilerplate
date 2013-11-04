module.exports = function(grunt) {
	var destDir = './result/';
	var _ = require('lodash');
	// "gem install" all of this:
	var compassExt	= [
		'breakpoint',
		'compass-recipes',
		'singularitygs',
		'compass',
		'sass-css-importer',
		'rails-sass-images'
	];

	var config = {
		pkg: grunt.file.readJSON( 'package.json' ),

		connect: {
			server: {
				options: {
					port: 8000,
					base: './'
				}
			}
		},

		watch: {
			scss: {
				files: ['scss/**/*.scss'],
				tasks: 'css'
			},
			html: {
				files: [destDir +'/**/*.html']
			},
			js: {
				files: ['js/**/*.js'],
				tasks: 'js'
			},
			livereload: {
				options: {
					livereload: 1337,
				},
				files: [
					destDir +'**/*.html',
					destDir +'css/{,*/}*.css',
					destDir +'js/{,*/}*.js'
				]
			}
		},

		autoprefixer: {
			options: {
				browsers: ['last 2 versions', '> 1%']
			},
			build: {
				src: 'css/styles.css',
				dest: 'css/styles.css'
			}
		},

		copy: {
			css: {
				files: [
					{ expand: true, src: ['./css/*.css'], dest: destDir }
				]
			}
		},

		concat: {
			main: {
				src: [
					'js/main/**/*.js',
					'!js/main/**/_*.js'
				],
				dest: destDir +'js/main.js'
			},
			scriptsWrap: {
				src: [
					'js/helpers/intro.js',
					destDir +'js/main.js',
					'js/helpers/outro.js'
				],
				dest: destDir +'js/main.js'
			},
			plugins: {
				src: [
					'js/plugins/**/*.js',
					'!js/plugins/**/_*.js',
					'js/plugins/_ga.js'
				],
				dest: destDir +'js/plugins.js'
			},
			pluginsWrap: {
				src: [
					'js/helpers/intro.js',
					destDir +'js/plugins.js',
					'js/helpers/outro.js'
				],
				dest: destDir +'js/plugins.js'
			}
		},

		'closure-compiler': {
			main: {
				closurePath		: 'js/helpers/closure-compiler/',
				js				: destDir +'js/main.js',
				jsOutputFile	: destDir +'js/main.min.js',
				noreport		: true,
				options: {
					compilation_level: 'SIMPLE_OPTIMIZATIONS' // or 'ADVANCED_OPTIMIZATIONS'
				}
			},
			plugins: {
				closurePath		: 'js/helpers/closure-compiler/',
				js				: destDir +'js/plugins.js',
				jsOutputFile	: destDir +'js/plugins.min.js',
				noreport		: true,
				options: {
					compilation_level: 'SIMPLE_OPTIMIZATIONS' // or 'ADVANCED_OPTIMIZATIONS'
				}
			}
		}
	};

	config.csso = {
		compress: {
			options: {
				restructure: true,
				report: false
			},
			files: {}
		}
	};
	config.csso.compress.files[destDir +'css/styles.min.css'] = [destDir +'css/styles.css'];

	var compassConfig = {
		require: compassExt,
		httpPath: '/',
		cssDir: 'css',
		sassDir: 'scss',
		imagesDir: destDir +'i',
		javascriptsDir: 'js',
		outputStyle: 'expanded',
		environment: 'development'
	};
	config.compass = {
		dev: {},
		prod: {}
	};
	config.compass.dev.options = _.merge(compassConfig, {
		debugInfo: true,
		environment: 'development'
	});
	config.compass.prod.options = _.merge(compassConfig, {
		debugInfo: false,
		environment: 'production'
	});


	grunt.initConfig(config);


	var cssTask = [
		'autoprefixer',
		'copy:css'
	];
	var jsTask = [
		'concat:plugins',
		'concat:pluginsWrap',
		'concat:main',
		'concat:scriptsWrap'
	];
	var minifyingTask = [
		'csso',
		'closure-compiler'
	]

	grunt.registerTask('css', ['compass:dev'].concat(cssTask));
	grunt.registerTask('js', jsTask);
	grunt.registerTask('min', minifyingTask);

	var productionConfig = ['compass:prod'].concat(cssTask, jsTask, minifyingTask);
	grunt.registerTask('default', productionConfig); // default task as a production config
	grunt.registerTask('prod', productionConfig);
	grunt.registerTask('dev', ['connect', 'watch']);

	require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);
};
