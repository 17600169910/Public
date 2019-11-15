####
简述：
    BML 一键集群清理脚本
    适用于BML2.8版本

使用说明:
    请将BML config文件复制到当前路径一份，用于脚本执行变量引用
    sh main.sh master   // 该指令将会清除当前master节点集群中所有组件
    sh main.sh cluster_slave   // 该指令将会自动清除BML（除master节点）外
其他所有节点，自动清除
