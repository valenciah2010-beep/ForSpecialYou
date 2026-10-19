# 生产部署记录

2026-10-14（Asia/Shanghai）。已将当前本地 Web 构建和 Node 代码部署至 `154.40.41.179`，入口为 https://fsyadmin.top。

| 项目 | 结果 |
| --- | --- |
| Web | `/www/wwwroot/default/dist`；入口与 JS/CSS 文件经过 HTTPS 获取并校验一致 |
| Node | `/www/wwwroot/default/server`；宝塔原有 `server` 项目启动入口 `index.js` 转发至 `src/index.js` |
| 运行环境 | Node 22.22.3，用户 `www`，仅监听 `127.0.0.1:3002` |
| API 地址 | Web 同源 `/api`；iOS/Android Release 为 `https://fsyadmin.top`，443 经 Nginx 转发至 3002 |
| 本地端口 | Web 5223、Node 4223，保持不变 |
| 版本核对 | 49 个源码、配置和构建文件 SHA-256 与本地一致；保留旧缓存资产供已打开页面加载 |
| 服务检查 | HTTPS 首页、健康接口、静态资产正常；管理员/家长鉴权只读访问、匿名与跨账号拦截通过 |

保留了原 TLS 证书配置，Nginx 校验后重载；请求体限制 20 MB，API 读取超时 65 秒，代理使用实际客户端地址，HTML 禁用缓存。服务继续由原宝塔 Node 项目管理，未额外启动 PM2。原项目配置已有开机启动标记，本次未通过整机重启验证。启动 PID 为 2755540；PID 会随后续重启变化，实际状态以宝塔 PID 文件和健康接口为准。

## 数据保护

完整数据库、旧代码、环境配置、Nginx 和面板项目配置均已备份至：

`/www/backup/ForSpecialYou/20261014-deploy`

旧目录额外保留为 `server.previous`、`dist.previous`。数据库备份为 `database-before.sql`，SHA-256：

`704fb82a500d35920df4dfcc26db0430809c9c7af32bd6119a2b1d0db2ad1c65`

仅新增迁移历史、会话、配额、审计、限流、上传基础表。未重置密码、转换角色、导入测试账号或写入原业务记录。迁移前、迁移后、启动后和线上只读测试后，对两张原业务表所有原字段按主键排序校验，数量与内容哈希均一致：

| 表 | 数量 | SHA-256 |
| --- | --- | --- |
| `users` | 17 | `4fff7d9274699365241cfa8bbbec356c2cf7a7c7463b1880093b61a17f404e8b` |
| `parent_app_data` | 13 | `b85902ee0d31b6f1ec8bb513f5a97d81c9119781e5d18f0a68ac3ce9e5b6e18d` |

## 测试与边界

- 本地前端构建、8 项单元测试和 14 项隔离集成测试通过。
- 服务器实际 MySQL 5.7.44 上使用独立临时库，迁移及重复迁移、8 项单元测试、14 项集成测试通过；临时库已删除。
- 线上 14 项 HTTP 检查通过；通过现有账号的临时会话读取管理员/家长接口，临时会话已撤销，未执行生产新增、删除、同步、改密或 AI 调用。
- Playwright 检查首页和登录页，桌面及 390px 窄屏显示正常，无 Vue 警告；未登录 `/api/admin/session` 的 401 为预期响应。截图保存在被忽略的 `output/playwright/production-login-*.png`。
- 最终检查时 Node 已连续运行超过 4 分钟，当前启动后的日志无错误；生产 `.env` 权限为 `600`，备份目录为 `700`，临时测试会话剩余 0。
- AI 当前 `AI_PROCESSING_ENABLED=false`，真实模型调用未测试。
- 原生代码已具备新鉴权及 Release 地址；本次未发布 iOS/Android 安装包，旧版无令牌客户端需更新并重新登录。

后续回滚以代码和配置为主，不应直接恢复数据库备份覆盖上线后的用户数据。新增基础表可保留；如确需数据库恢复，应另行核对数据时间点。
