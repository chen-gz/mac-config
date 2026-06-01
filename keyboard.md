# 预设快捷键与别名配置 (Preset Keybindings & Aliases)

本文件整理了当前系统配置中预置的快捷键（Helix, Tmux）、Fish Shell 别名以及 AI 编程助手命令行工具的默认快捷键。

## 1. Tmux 面板与导航快捷键 (Tmux Window & Pane Navigation)

配置文件: [tmux.nix](file:///Users/guangzong/.config/nix-darwin/modules/tmux.nix)

| 快捷键 (Keybinding) | 执行动作 (Action) | 说明 (Description) |
| --- | --- | --- |
| `Ctrl + a` (`C-a`) | tmux 前缀键 (Prefix Key) | 替换了默认的 `Ctrl + b`；再次按 `Ctrl + a` 可发送前缀本身 |
| `Prefix` + `h` | 选择左侧面板 (`select-pane -L`) | 方向导航（类 Vim） |
| `Prefix` + `j` | 选择下方面板 (`select-pane -D`) | 方向导航（类 Vim） |
| `Prefix` + `k` | 选择上方面板 (`select-pane -U`) | 方向导航（类 Vim） |
| `Prefix` + `l` | 选择右侧面板 (`select-pane -R`) | 方向导航（类 Vim） |
| `Ctrl + h` | 直接选择左侧面板 | 无需前缀键，直接切换面板 |
| `Ctrl + j` | 直接选择下方面板 | 无需前缀键，直接切换面板 |
| `Ctrl + k` | 直接选择上方面板 | 无需前缀键，直接切换面板 |
| `Ctrl + l` | 直接选择右侧面板 | 无需前缀键，直接切换面板 |

---

## 2. Helix 文本编辑器快捷键 (Helix Editor)

配置文件: [helix.nix](file:///Users/guangzong/.config/nix-darwin/modules/helix.nix)

| 模式 (Mode) | 快捷键 (Keybinding) | 执行动作 (Action) | 说明 (Description) |
| --- | --- | --- | --- |
| **Normal (普通模式)** | `q` | `:quit` | 快速退出编辑器 |
| **Insert (编辑模式)** | `jj` | `normal_mode` | 快速返回普通模式 |
| | `jk` | `normal_mode` | 快速返回普通模式 |

---

## 3. Fish 命令行别名与快捷指令 (Fish Shell Aliases & Functions)

配置文件: [fish.nix](file:///Users/guangzong/.config/nix-darwin/modules/fish.nix) 和 [guangzong.nix](file:///Users/guangzong/.config/nix-darwin/guangzong.nix)

| 快捷指令 (Alias/Func) | 映射命令 (Mapped Command) | 说明 (Description) |
| --- | --- | --- |
| `ls` | `eza --icons --git` | 使用 modern ls (eza) 展示图标和 Git 状态 |
| `cat` | `bat` | 使用带语法高亮的 bat 替代 cat |
| `vi` | `hx` | 默认编辑器使用 Helix |
| `lg` | `lazygit` | 启动 Lazygit TUI |
| `lj` | `lazyjj` | 启动 Lazyjj TUI |
| `y` (函数) | `yazi` with directory memory | 退出 yazi 时自动 cd 到最后浏览的目录 |
| `G` / `gemini` | `agy` | 启动 AI 编程助手 |
| `nixconf` | `cd ~/.config/nix-darwin` | 快速进入 nix-darwin 配置目录 |
| `blog` | `cd ~/Documents/chen-gz.github.io` | 进入个人博客目录 |
| `cf` | `cd ~/Documents/cf_template && hx main.cpp` | 快速开始 Codeforces 刷题配置 |
| `top` | `btop` | 使用 btop 系统监控工具 |
| `jq` | `jql` | 使用 jql 工具处理 json |
| `df` | `duf` | 更好的磁盘空间展示工具 |
| `du` | `dust` | 更好的目录空间分析工具 |
| `man` | `tldr` | 使用简易版手册 tldr |
| `hexdump` | `hexyl` | hex 预览工具 |
| `dr` | `devenv tasks run` | 运行 devenv 任务 |
| `ds` | `devenv shell` | 进入 devenv 开发环境 |
| `gpgrestart` | `gpg-connect-agent reloadagent /bye && ssh-add -D` | 重启 gpg-agent 并重置 ssh 密钥 |
| `clean` | `atuin search --exclude-exit=0 "" --delete` | 清理命令行历史记录 |
| `dcgen` | `devenv eval devcontainer.settings \| jq '."devcontainer.settings"' > .devcontainer.json` | 导出并生成 devcontainer 配置文件 |
| `gg_update` | `~/.config/nix-darwin/zig-out/bin/bootstrap update && ~/.config/nix-darwin/zig-out/bin/bootstrap deploy gg-mac` | 更新并部署当前 Mac 配置 |
| `gg_deploy` | `~/.config/nix-darwin/zig-out/bin/bootstrap deploy gg-mac` | 部署当前 Mac 配置 |
| `gg_clean` | `~/.config/nix-darwin/zig-out/bin/bootstrap clean` | 清理配置编译残留 |

---

## 4. Fish & FZF 辅助快捷键 (Fish Shell & FZF Helper Keys)

这些是 Fish Shell 与 FZF 工具链提供的开箱即用快捷键：

| 快捷键 (Keybinding) | 来源 (Source) | 执行动作 (Action) | 说明 (Description) |
| --- | --- | --- | --- |
| `Alt + c` | FZF | 模糊搜索并进入子目录 (`fzf-cd-widget`) | 快速跳转目录 |
| `Alt + l` | Fish | 列出当前或光标所在目录内容 | 相当于快速执行 `ls` 预览 |
| `Alt + d` | Fish | 删除下一个单词 / 预览历史目录 | 输入内容时删除光标后的下一个单词；输入为空时列出最近访问过的目录历史 |
| `Ctrl + r` | FZF | 模糊搜索并执行历史命令 | 查找以前输入过的命令 |
| `Ctrl + t` | FZF | 模糊搜索并向当前命令行插入文件路径 | 快速插入文件名/路径 |

---

## 5. Antigravity CLI AI 助手预设快捷键 (Antigravity CLI Keybindings)

配置文件: `~/.gemini/antigravity-cli/keybindings.json`

这些是在当前终端交互式运行 AI 编程助手命令行界面时的控制键：

| 功能分类 (Category) | 快捷键 (Keybinding) | 执行动作 (Action) |
| --- | --- | --- |
| **基础控制** | `ctrl+l` | 清除屏幕 (`cli.clear_screen`) |
| | `enter` | 确认并提交输入 (`cli.enter`) |
| | `ctrl+c`, `esc` | 取消当前输入/中断 (`cli.escape`) |
| | `ctrl+d` | 退出/终止会话 (`cli.exit`) |
| | `ctrl+z` | 挂起 CLI 任务 (`cli.suspend`) |
| **输入与编辑** | `ctrl+g` | 打开外部编辑器编辑输入框内容 (`edit.open_editor`) |
| | `ctrl+v` | 粘贴 (`edit.paste`) |
| | `ctrl+y` | 粘贴最近剪切板/Yank 的内容 (`edit.yank`) |
| | `ctrl+shift+z` | 重做刚才的操作 (`edit.redo`) |
| | `ctrl+_`, `ctrl+shift+-` | 撤销刚才的操作 (`edit.undo`) |
| | `alt+enter`, `ctrl+j`, `shift+enter` | 在输入框中插入新行 (`prompt.insert_newline`) |
| **导航** | `up` / `down` | 向上/向下滚动或选择 |
| | `left` / `right` | 向向左/向右移动光标 |
| | `ctrl+home` | 跳到顶部 (`navigation.go_to_top`) |
| | `ctrl+end` | 跳到底部 (`navigation.go_to_bottom`) |
| | `pgup` / `shift+up` | 向上翻页 (`navigation.page_up`) |
| | `pgdown` / `shift+down` | 向下翻页 (`navigation.page_down`) |
| | `tab` | 切换焦点/选项补全 (`navigation.tab`) |
| **助手确认** | `y` | 确认系统提出的方案/操作 (`confirm.yes`) |
| | `n` | 拒绝系统提出的方案/操作 (`confirm.no`) |
| | `e` | 编辑系统提出的命令行 (`confirm.edit_command`) |
| **子代理与视图** | `ctrl+k` | 快速批准子代理任务授权 (`subagent.approve_fast`) |
| | `alt+j` | 快速跳转到等待响应 of 子任务 (`subagent.jump_to_waiting`) |
| | `ctrl+r` | 审查生成的 artifacts (`view.review_artifact`) |
| | `ctrl+o` | 展开/折叠执行轨迹面板 (`view.toggle_trajectory`) |
