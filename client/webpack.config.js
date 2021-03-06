/* eslint-disable */
const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');
const WebappWebpackPlugin = require('webapp-webpack-plugin');
const WorkboxPlugin = require('workbox-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer')
  .BundleAnalyzerPlugin;

// TODO: Support legacy + modern bundles:
// https://philipwalton.com/articles/deploying-es2015-code-in-production-today/

const y = new Date().getFullYear();
const COPYRIGHT = 'Copyright ' + y + ' Taito United Oy - All rights reserved.';
const OUTPUT_DIR = '../../build';
const ASSETS_DIR = 'assets';
const PWA_ICON_DIR = ASSETS_DIR + '/icon.png';
// TODO: DOCKER_HOST contains the host ip? Use it instead of the hard coded ip
const PUBLIC_HOST = process.env.DOCKER_HOST ? '192.168.99.100' : 'localhost';
const PUBLIC_PORT = process.env.COMMON_PUBLIC_PORT;
const DEV_PORT = 8080;
const DEV_POLL =
  (process.env.HOST_OS == 'macos' || process.env.HOST_OS == 'windows') &&
  !process.env.DC_COMMAND
    ? 2000
    : undefined;

module.exports = function(env, argv) {
  const isProd = !!env.production;
  const analyzeBundle = isProd && process.env.ANALYZE_BUNDLE === 'true';

  return {
    mode: isProd ? 'production' : 'development',

    devtool: isProd ? 'source-maps' : 'inline-source-map',

    entry: ['src/index'],

    output: {
      // Use [contenthash] for better caching support
      filename: isProd ? '[name].[contenthash].js' : '[name].bundle.js',
      path: path.resolve(__dirname, OUTPUT_DIR),
      publicPath: '/',
    },

    resolve: {
      modules: [path.resolve('.'), 'node_modules'],
      extensions: ['.json', '.mjs', '.jsx', '.js', '.ts', '.tsx'],
      // Add aliases here and remember to update tsconfig.json "paths" too
      alias: {
        '~common': path.resolve(__dirname, 'src/common'),
        '~services': path.resolve(__dirname, 'src/common/services'),
        '~shared': path.resolve(__dirname, 'shared'),
        '~theme': path.resolve(__dirname, 'src/common/theme'),
        '~ui': path.resolve(__dirname, 'src/common/ui/index'),
        '~utils': path.resolve(__dirname, 'src/common/utils'),
      },
    },

    plugins: [
      // No need to type check when analyzing the JS bundle
      // NOTE: if type checking fails -> the build will fail
      !analyzeBundle && new ForkTsCheckerWebpackPlugin(),

      new HtmlWebpackPlugin({
        title: 'full-stack-template',
        version: process.env.BUILD_VERSION,
        imageTag: process.env.BUILD_IMAGE_TAG,
        template: 'index.html.template',
        inject: 'body',
      }),

      // Extract imported CSS into separate file for caching
      new MiniCssExtractPlugin({
        filename: isProd ? '[name].[contenthash].css' : '[name].css',
      }),

      new WebappWebpackPlugin({
        /* TODO:
         * At the moment there is a bug where the generated png icon
         * will have an ugly grey border around it but it should be fixed
         * as soon as `webapp-webpack-plugin` updates it's dependency of
         * https://github.com/haydenbleasel/favicons
         * So keep an eye on updates for `webapp-webpack-plugin` !!!
         */
        logo: path.resolve(__dirname, PWA_ICON_DIR),
        cache: true, // Make builds faster
        prefix: 'assets/', // Where to put pwa icons, manifests, etc.
        favicons: {
          appName: 'full-stack-template',
          appShortName: 'Taito',
          appDescription: 'Taito template app',
          developerName: 'Taito United',
          developerURL: 'https://github.com/TaitoUnited',
          background: '#ffffff',
          theme_color: '#15994C',
          orientation: 'portrait',
          display: 'standalone',
          start_url: '.',
          icons: {
            // Don't include unnecessary icons
            coast: false,
            yandex: false,
            windows: false,
          },
        },
      }),

      // If you use moment add any locales you need here
      new webpack.ContextReplacementPlugin(/moment[/\\]locale$/, /en|fi/),

      // Caching -> vendor hash should stay consistent between prod builds
      isProd && new webpack.HashedModuleIdsPlugin(),

      // Enable HRM for development
      !isProd && new webpack.HotModuleReplacementPlugin(),

      analyzeBundle && new BundleAnalyzerPlugin(),

      new webpack.DefinePlugin({
        'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
        'process.env.API_URL': JSON.stringify(process.env.API_URL),
        'process.env.SENTRY_PUBLIC_DSN': JSON.stringify(
          process.env.SENTRY_PUBLIC_DSN
        ),
        'process.env.GA_TRACKING_ID': JSON.stringify(
          process.env.GA_TRACKING_ID
        ),
      }),

      new webpack.BannerPlugin({ banner: COPYRIGHT }),

      // Generate a Service Worker automatically to cache generated JS files
      // NOTE: this should be the last plugin in the list!
      new WorkboxPlugin.GenerateSW({
        swDest: 'sw.js',

        clientsClaim: true,

        // NOTE: `skipWaiting` with lazy-loaded content might lead to nasty bugs
        // https://stackoverflow.com/questions/51715127/what-are-the-downsides-to-using-skipwaiting-and-clientsclaim-with-workbox
        skipWaiting: false,

        // Exclude images from the precache
        exclude: [/\.(?:png|jpg|jpeg|svg)$/],

        runtimeCaching: [
          {
            urlPattern: /\.(?:png|gif|jpg|jpeg|svg)$/,
            handler: 'CacheFirst',
          },
          {
            urlPattern: /.*(?:googleapis|gstatic)\.com/,
            handler: 'StaleWhileRevalidate',
          },
        ],
      }),
    ].filter(Boolean),

    module: {
      rules: [
        {
          test: /\.tsx?$/,
          enforce: 'pre',
          loader: 'eslint-loader',
          options: {
            quiet: true, // Don't report warnings
          },
        },

        {
          test: /\.(js|tsx?)$/,
          use: ['babel-loader'],
          exclude: /node_modules/,
        },

        {
          test: /\.js$/,
          use: ['source-map-loader'],
          enforce: 'pre',
        },

        {
          test: /\.(png|svg|jpg|gif)$/,
          use: ['file-loader'],
          exclude: /node_modules/,
        },

        {
          test: /\.css$/,
          use: [
            // NOTE: don't extract CSS in development
            isProd ? MiniCssExtractPlugin.loader : 'style-loader',
            'css-loader',
          ],
        },
      ],
    },

    optimization: {
      // Split runtime code into a separate chunk
      runtimeChunk: 'single',

      // Extract third-party libraries (lodash, etc.) to a separate vendor chunk
      splitChunks: {
        cacheGroups: {
          // Separate sentry into it's own bundle since it is huge
          sentry: {
            test: /[\\/]node_modules[\\/](@sentry)[\\/]/,
            name: 'sentry',
            chunks: 'all',
            priority: 30,
          },

          // Group most libs into one vendor bundle
          vendor: {
            test: /[\\/]node_modules[\\/]/,
            name: 'vendors',
            chunks: 'all',
            priority: 20,
          },

          // TODO: not sure if this is necessary...
          // This puts eg. ui components into a separate chunk.
          // https://itnext.io/react-router-and-webpack-v4-code-splitting-using-splitchunksplugin-f0a48f110312
          common: {
            name: 'common',
            minChunks: 2,
            chunks: 'async',
            priority: 10,
            reuseExistingChunk: true,
            enforce: true,
          },
        },
      },
    },

    devServer: isProd
      ? undefined
      : {
          host: '0.0.0.0',
          port: DEV_PORT,
          public: `${PUBLIC_HOST}:${PUBLIC_PORT}`, // Fix HMR inside Docker container
          contentBase: [
            path.join(__dirname, 'assets')
          ],
          hot: true,
          historyApiFallback: true,
          stats: 'minimal',
          disableHostCheck: true, // For headless cypress tests running in container
          lazy: false,
          watchOptions: {
            aggregateTimeout: 300,
            poll: DEV_POLL,
          },
          proxy: {
            '/api/*': {
              target: `http://server:${PUBLIC_PORT}`,
              pathRewrite: {
                '/api': '',
              },
            },
            '/socket.io/*': {
              target: `http://server:${PUBLIC_PORT}`,
              ws: true,
            },
          },
        },
  };
};
