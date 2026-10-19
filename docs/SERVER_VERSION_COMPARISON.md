# 线上与本地版本对比

检查时间：2026-10-14 12:45 +0800。以下是部署前的历史对比；后续已部署当前本地 Web/Node，并验证 49 个源码、配置和构建文件一致，见 [部署记录](DEPLOYMENT_2026-10-14.md)。

结论：服务器 154.40.41.179 上的 Web 和 Node 均与本地当前工作区版本不同。

| 模块 | 线上目录 | 本地当前目录 | 结果 |
| --- | --- | --- | --- |
| Web | `/www/wwwroot/default/dist` | `/Users/zjy/project/ForSpecialYou/admin-web/dist` | HTML、JS、CSS 构建产物不同 |
| Node | `/www/wwwroot/default/server` | `/Users/zjy/project/ForSpecialYou/server/src` | 18 个线上源码文件中，16 个对应文件不同，2 个旧文件已被替换；当前新增 14 个模块 |

## Node 内容证据

按文件内容的 SHA-256 比较，线上全部 18 个 JavaScript 源码文件与 `/Users/zjy/project/ForSpecialYou-main/server` 完全一致，也与当前仓库修复前的 `HEAD`（65b7aaf）完全一致。当前工作区包含尚未提交的修复，不能只用 Git 提交号判断当前代码相同。

线上 package.json 为 `demo-auth-app`，当前后端工作区为 `forspecialyou-server`。线上保留旧目录与启动入口，当前入口为 `server/src/index.js`。线上 API 配置仍使用 3002；本地当前使用 4223。

## Web 内容证据

| 文件 | 线上 | 本地当前 |
| --- | --- | --- |
| JS | `assets/index-C3IqjldS.js`，159427 字节 | `assets/index-oLeMKhsE.js` |
| CSS | `assets/index-BXdLPPvn.css`，30197 字节 | `assets/index-BO_dOOkJ.css` |
| 入口 HTML | SHA-256 `01d5a3eea0be4c123cf3011ebb3e168db0e9b2bb8763e09177cc2adb5739f96c` | 内容不同，含新增 favicon 引用 |

公共图片 `sakura-lake.png` 内容一致；这不代表应用版本一致。线上仅有构建文件，没有 Web 源码或构建版本标记，无法据此确定准确前端提交号；可以确定部署产物与当前本地构建不一致。

本轮新增的鉴权、服务端配额、图片分片上传、正式数据库迁移和模块拆分尚未反映到线上目录。
