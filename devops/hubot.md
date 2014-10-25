Platform - CentOS

Install node and npm
-----

yum -y groupinstall 'Development tools'

yum install redis; mv /etc/redis.conf /etc/redis/redis/conf

npm install -g coffee-script



1. [install url](https://gist.github.com/isaacs/579814)

PreInstall

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

安装Adapter
-----

1. [QQ Adapter]()

2. [GTalk Adapter]()

3. [Slack Adapter]()

在package.json的dependencies中添加hubot-slack:

    "hubot-slack": "~2.0.4"

然后运行 npm install

设置slack相关变量

    export HUBOT_SLACK_TOKEN=你的Token	  #从slack网站获得
    export HUBOT_SLACK_TEAM=vuur
    export HUBOT_SLACK_BOTNAME=vuurhubot

启动
    nohup ./bin/hubot --adapter slack --name kucat &

然后在slack.com增加hubot集成

    http://你的hubot server:8080/

需要注意的是,slack—adapter需要部署机有固定ip或域名，需要填写到slack的网站上

slack自带机器人，hubot-adapter是取代该机器人的，所以不用单独申请一个机器人账号。

如果需要作为单独账号服务，请使用hubot-irc，然后使用slack的irc gateway，在slack网站上开通irc的访问权限

    Create a "user" account for Hubot
    Login to your slack instance as your hubot user
    Goto https://yourdomain.slack.com/account/gateways
    Use the irc connection info in the Hubot specific variables for hubot-irc
    Fire up hubot and watch it connect

    # Make this file executable and run from your hubot directory
    HUBOT_IRC_SERVER="yourdomain.irc.slack.com" \
    HUBOT_IRC_ROOMS="#general,#random" \
    HUBOT_IRC_NICK="slackbot" \
    HUBOT_IRC_PASSWORD="yourdomain.1239586t437389" \
    HUBOT_IRC_NICKSERV_PASSWORD="yourdomain.129319823719" \
    HUBOT_IRC_UNFLOOD="false" \
    HUBOT_IRC_USESSL=1
    bin/hubot -a irc --name hitbot

4. [HipChat Adapter](https://github.com/hipchat/hubot-hipchat)

yum install -y libicu-devel compat-expat

在package.json的dependencies中添加hubot-hipchat

npm install --save hubot-hipchat

    #JID是https://vuur.hipchat.com/account/xmpp这里的ID，不是注册账号。应该是类似123_456@chat.hipchat.com的格式
    >>> export HUBOT_HIPCHAT_JID=""
    #这是个注册的密码
    >>> export HUBOT_HIPCHAT_PASSWORD=""

5. [Hubot-XMPP](https://github.com/markstory/hubot-xmpp)



