
可以查看源码文件，得到部分选项的注释

    src/common/legacy_config_opts.h

// mark any booting osds 'in'
mon_osd_auto_mark_in = false

// seconds, set to 24h
mon_osd_down_out_interval = 86400

// mark booting auto-marked-out osds 'in'
mon_osd_auto_mark_auto_out_in = false

    auto-marked-out flat
    $ ceph osd dump
    osd.1 down out weight 0 up_from 8 up_thru 33 down_at 35 last_clean_interval [0,0)  autoout,exists


//  mark booting new osds 'in'
mon_osd_auto_mark_new_in = false

