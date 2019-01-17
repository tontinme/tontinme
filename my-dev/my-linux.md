# personal linux os tune

## zsh

install zsh

```
yum install zsh
chsh -s /bin/zsh
```

install oh my zsh

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

apply zsh theme

```
cp zshrc to /root/.zshrc
```

zsh语法高亮，这个插件安装之后主要效果就是命令高亮，如果是错误的命令，颜色是红色，正确的命令是绿色的

```
cd .oh-my-zsh/plugins
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
echo "source /root/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
source ~/.zshrc
```

## 配置vim

升级到vim8

```
yum upgrade vim-minimal vim-common vim-enhanced
```

将vimrc, .vim/目录等配置放在~/目录下后，先安装vundle
git clone http://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
然后打开vim，执行:BundleInstall，安装插件
更新插件 :BundleInstall!
卸载不在列表中的插件 :BundleClean

