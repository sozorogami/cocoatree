# cocoatree

A Vapor webapp that creates a human-readable chart of your Cocoapods dependencies. Just copy/paste the contents of your `Podfile.lock` and click submit!

<img width="511" alt="podfile_lock_fyi" src="https://user-images.githubusercontent.com/1407680/35017211-d5b7b10c-fae9-11e7-82cd-f9e7bbb61021.png">

Currently deployed at [podfile.lock.fyi](http://podfile.lock.fyi).

## Building

1. Make sure you have Vapor installed https://docs.vapor.codes/2.0/getting-started/install-on-macos/

2. Build the project using the Vapor CLI tool: `vapor build`

3. Add a crypto file. You'll need to set a hash and cipher in `Config/secrets/crypto.json`. (This directory is ignored by version control.) During development, you can use Vapor's default settings:

    ```
    {
        "hash": {
            "method": "sha256",
            "encoding": "hex",
            "key": "0000000000000000"
        },
    
        "cipher": {
            "method": "aes256",
            "encoding": "base64",
            "key": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        }
    }
    ```

    Vapor will warn you that these values should not be used in production, and will provide instructions for generating your own.

4. Run the project. You should now be able to run the app, either by opening the Xcode project, or by installing Vapor's command line tools and executing `vapor run` in the project's root directory. By default, this will start a webserver at `localhost:1612`. You can change the port by editing `Config/server.json`.

## Acknowledgements

This project was originally conceived at a Tumblr Hack Day in 2017.

Backend is in [Vapor](https://github.com/vapor/vapor), frontend uses [dagre](https://github.com/dagrejs/dagre) for layout and [Cytoscape.js](https://github.com/cytoscape/cytoscape.js) for rendering.
