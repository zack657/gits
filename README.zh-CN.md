# Git 账号绑定器

[English](README.md)

Git 账号绑定器是一个 macOS 原生工具，用来解决一台电脑上同时维护多个 Git 账号时的配置混乱问题。它的核心思路很简单：创建 Git 账号，把仓库绑定到对应账号，然后安全地应用本地 Git 配置。

## 为什么需要它

Git 自带配置能力很强，但当个人项目、公司项目、客户项目混在一台机器上时，手动维护 `user.name`、`user.email`、SSH key 和仓库绑定关系很容易出错。这个 App 提供一个可视化配置层，同时仍然使用 Git 和 SSH 的标准机制，配置结果对普通 Git 命令透明。

## 当前能力

- 管理多个 Git 账号，包括 Git 用户名和邮箱。
- 新增 GitHub 账号时自动生成独立 SSH key。
- 复制 public key，并打开 GitHub SSH key 设置页面。
- 真实测试生成的 SSH key 是否能连接 GitHub，并且只有认证到的 GitHub 登录名匹配当前账号时才标记就绪。
- 新增和删除本地仓库管理项。
- 将每个仓库绑定到指定 Git 账号。
- 将绑定关系应用到仓库本地 `.git/config`。
- 写入仓库级 `user.name`、`user.email` 和 `core.sshCommand`。
- 每次应用配置前自动创建快照。
- 在历史版本里查看快照，并恢复到任意旧版本。
- 使用 SQLite 持久化 App 状态。
- 默认界面语言为简体中文。

## 安全模型

App 的运行时数据存储在：

```text
~/Library/Application Support/GitAccountBinder
```

生成的 SSH private key、public key、SQLite 数据库、快照、构建产物和本地工具配置都不会提交到 Git。请不要提交真实密钥、本地数据库、日志或环境变量文件。

应用 Git 配置前，App 会先为受影响仓库的配置文件创建快照。随后只写入仓库本地配置，所以全局 Git 默认账号仍然可以作为兜底行为存在。

## GitHub SSH key 使用说明

App 生成的 key 应该添加到 GitHub 账号级设置：

```text
GitHub Settings -> SSH and GPG keys
```

不要把这些账号 key 添加到仓库的 Deploy keys。Deploy keys 是仓库级 key，不属于当前 MVP 范围。

把 public key 添加到 GitHub 后，请在 App 里点击连接测试按钮。如果 GitHub 认证出来的是另一个账号，这个账号不应被标记为就绪。

## 环境要求

- macOS 14 或更新版本
- Swift 6.3 工具链
- Git
- SSH 和 `ssh-keygen`

## 构建和运行

运行测试：

```bash
swift test
```

构建并启动 macOS App：

```bash
./script/build_and_run.sh
```

构建并验证 App 可以启动：

```bash
./script/build_and_run.sh --verify
```

## 项目结构

- `GitAccountBinder/`：macOS App 源码。
- `GitAccountBinderTests/`：Swift Testing 测试套件。
- `docs/superpowers/specs/`：产品和架构说明。
- `docs/superpowers/plans/`：实现计划。
- `script/`：本地开发脚本。

## 当前状态

这是早期 MVP。当前版本已经可以用于本地 Git 账号绑定，但仍然保持了一些保守边界：

- GitHub SSH key 仍然需要手动添加。
- 目录级默认账号规则还会继续扩展。
- 暂未实现 commit signing 全生命周期。
- 暂不支持云同步和团队策略管理。

## 参与贡献

提交 issue 或 pull request 前，请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 安全问题

请不要通过公开 issue 报告敏感安全问题，详见 [SECURITY.md](SECURITY.md)。

## 许可证

当前尚未选择开源许可证。在正式添加许可证之前，仓库所有权利由仓库所有者保留。
