# rpm制作源 签名

[link](https://gist.github.com/fernandoaleman/1376720/aaff3a7a7ede636b6913f17d97e6fe39b5a79dc0)

1. 生成key或者导入key

    gpg --gen-key  # 选项都默认即可，需要填写用户名和邮箱
    gpg --list-keys

或者导入key。公钥和私钥都需要导入
    
    # public key
    gpg --import RPM-GPG-KEY-umcloud
    # private key
    gpg --allow-secret-key-import --import secret-umcloud
    gpg --list-secret-key

附：导出公钥，私钥

    # public key
    gpg --export -a 'umcloud' > RPM-GPG-KEY-umcloud
    # private key
    gpg --export-secret-key -a umcloud > secret-umcloud

2. 导入rpm并签名

    rpm --import RPM-GPG-KEY-umcloud

确认是否导入成功

    rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'

生成.rpmmacros

    # vi ~/.rpmmacros
    # %_signature => This will always be gpg
    # %_gpg_path  => Enter full path to .gnupg in your home directory
    # %_gpg_name  => Use the Real Name you used to create your key
    # %_gpbin     => run `which gpg` (without ` marks) to get full path 
    
    %_signature gpg
    %_gpg_path /root/.gnupg
    %_gpg_name umcloud
    %_gpgbin /usr/bin/gpg`)

签名

    # 单个签名
    rpm --addsign git-1.7.7.3-1.el6.x86_64.rpm
    # 多个签名
    rpm --addsign *.rpm

检查是否签名成功

    rpm --checksig (sha1) dsa sha1 md5 gpg OK

然后再生成源

    createrepo -pdo xx/el7/x86_64/
