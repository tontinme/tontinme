Platform - CentOS

Install node and npm
-----

1. [install url](https://gist.github.com/isaacs/579814)

    # this way is best if you want to stay up to date
    # or submit patches to node or npm

    mkdir ~/local
    echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc
    . ~/.bashrc

    # could also fork, and then clone your own fork instead of the official one

    git clone git://github.com/joyent/node.git
    cd node
    ./configure --prefix=~/local
    make install
    cd ..

    git clone git://github.com/isaacs/npm.git
    cd npm
    make install # or `make link` for bleeding edge
2. Install with yeoman

    >>> npm install -g yo generator-hubot
    >>> yo --help	  #查看是否安装成功generator-hubot
    >>> mkdir myhubot
    >>> cd myhubot
    >>> yo hubot

**error**

Error hubot
You don't seem to have a generator with the name hubot installed.

手动安装:

    >>> ls node_modulles/generator-hubot/
    README.md  node_modules  package.json
    >>> cd ~/local/lib/node_modules/	  #cd /usr/local/lib/node_modules/
    >>> git clone git://github.com/github/generator-hubot.git
    >>> cd generator-hubot/
    >>> npm install

安装scripts
-----

There are three main sources to load scripts from:

* all scripts bundled with your hubot installation under scripts/ dir

* community scripts specified in hubot-scripts.json and shipped in the hubot-scripts npm package

* scripts loaded from external npm packages and specified in external-scripts.json








