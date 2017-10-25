const path = require("path");
const webpack = require("webpack");
var CopyWebpackPlugin = require("copy-webpack-plugin");

const srcPath = path.resolve("src");
const distPath = path.resolve("dist");

module.exports = {
    entry: {
        app: "./src/Index.ts",
    },

    output: {
        filename: "[name].js",
        path: distPath
    },

    resolve: {
        extensions: [".ts", ".tsx", ".js", ".jsx", ".elm"]
    },

    devtool: "source-map",

    module: {
        rules: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "elm-webpack-loader",
            },
            {
                test: /\.tsx?$/,
                loader: "awesome-typescript-loader"
            },
            {
                test: /\.css$/,
                use: [
                    "style-loader",
                    "css-loader"
                ]
            },
            {
                test: /\.(png|svg|jpg|gif)$/,
                use: [
                    "file-loader"
                ]
            }
        ]
    },
    plugins: [
        new CopyWebpackPlugin([
            {
                from: path.join(srcPath, "index.html"),
                to: path.join(distPath, "index.html")
            },
            {
                from: path.join(srcPath, "static"),
                to: distPath
            },
        ])
    ]
};
