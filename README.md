# sercli
| 分类 | 命令格式 | 说明 |
|------|----------|------|
| **模块管理** | `sercli create module <模块名>` | 创建模块 |
| | `sercli delete module <模块名>` | 删除模块 |
| **子命令管理** | `sercli set command <模块> <子命令>=<别名>` | 设定别名（指向同模块子命令） |
| | `sercli set command <模块> <子命令>=function.<文件名>` | 设定子命令指向脚本文件（默认函数名与子命令相同） |
| | `sercli set command <模块> <子命令>=function.<文件名>(<函数名>)` | 设定子命令指向脚本中的指定函数 |
| | `sercli set command <模块> <子命令>=NULL` | 删除子命令 |
| | `sercli delete command <模块> <子命令>` | 删除子命令 |
| **函数导入** | `sercli import function <模块> <子命令>=<脚本路径>` | 从脚本路径导入函数作为子命令（示例：`sercli import function nginx restart=./restart.sh`） |
| **快速调用** | `sercli set module <模块名> link="<链接名>"` | 设置模块链接名，配合软链接使用（如：`ngcli start`），如果你没有创建软链接权限 可以使用alias xxx="MODULE_NAME=xxx sercli",该方式无需使用set module link|
| **其他设置** | `sercli set sort module` | 模块在前（默认） |
| | `sercli set sort command` | 命令在前 |
| | `sercli set redirect <数值>` | 设置重定向限制 |
| | `sercli set force true/false/off` | 设置严格模式 |
| **安全审计** | `sercli check sudo` | 检查 sudo 配置 |
| | `sercli rebuild cache` | 重建命令缓存 |
| **查询** | `sercli list command [匹配模式]` | 列出命令（支持匹配模式过滤） |
| | `sercli list module` | 列出所有模块 |
| | `sercli info <模块名>` | 查看模块详细信息 |