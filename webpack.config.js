/* eslint-env node */

'use strict'

const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const postcssNested = require('postcss-nested')
const autoprefixer = require('autoprefixer')
const path = require('path')

module.exports = {
	mode: 'development',
  entry: {
    content: './src/content',
    options: './src/options',
  },
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: '[name].js',
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
          },
          {
            loader: 'css-loader',
            options: {
              importLoaders: 1,
            },
          },
          {
            loader: 'postcss-loader',
            options: {
              plugins: [
								postcssNested,
								autoprefixer,
							],
            },
          },
        ],
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].css',
      chunkFilename: '[id].css',
    }),
  ],
}
