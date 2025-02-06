/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  images: { unoptimized: true },
  eslint: {
    ignoreDuringBuilds: true,
  },
  // Improve chunk loading reliability
  webpack: (config) => {
    // Simplified Webpack configuration
    config.optimization.splitChunks = {
      chunks: 'all',
      minSize: 20000,
      maxSize: 70000,
      minChunks: 1,
      cacheGroups: {
        default: false,
        vendors: false,
      },
    };

    return config;
  },
};

module.exports = nextConfig;