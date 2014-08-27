Intro
-----

Command
-----

    $docker
    $docker --help
    $docker run --help

Some Example:

    $docker build [OPTIONS] PATH | URL | -	
 #从源码构建新image命令

    $docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
 #把有修改的container提交成新的image。docker的建议，应该写一个新的Dockerfile文件来维护此image，commit仅作一个临时创建image的辅助命令

    $docker cp CONTAINER:PATH HOSTPATH
 #可以把容器内的文件复制到host主机上

    $docker diff CONTAINER
 #diff会列出容器内文件变化状态(Add,Delete,Change)的列表清单

    $docker export CONTAINER > latest.tar
 #把容器系统文件打包，方便分发给其他系统使用

    $docker import|load|save
	  $docker import URL|- [REPOSITORY[:TAG]]
	  $docker load
	  $docker save IMAGE
 #加载(import|load),导出(save)容器系统文件

    $docker tag [OPTIONS] IMAGE [REGISTRYHOST/][USERNAME/]NAME[:TAG]
 #组合使用用户名，image名字，标签名来管理image

    $docker events [OPTIONS]
 #打印容器实时的系统事件

    $docker history [OPTIONS] IMAGE
 #打印指定image中每一层image命令行的历史记录
