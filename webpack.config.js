/* eslint-env node */

'use strict'

const ExtractTextPlugin = require('extract-text-webpack-plugin')
const postcssNested = require('postcss-nested')
const autoprefixer = require('autoprefixer')

module.exports = {
	entry: {
		'content': './src/content',
		'options': './src/options'
	},
	output: {
		path: './build/',
		filename: '[name].js'
	},
	module: {
		loaders: [
			{
				test: /\.css$/,
				loader: ExtractTextPlugin.extract(
					'style-loader',
					'css-loader!postcss-loader'
				)
			}
		]
	},
	plugins: [
		new ExtractTextPlugin('[name].css')
	],
	postcss: function() {
		return [
			postcssNested,
			autoprefixer
		]
	}
}
