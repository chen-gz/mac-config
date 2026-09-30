# macOS 媒体服务器与存储阵列运维重配置指南 (Server & Storage Maintenance Guide)

本文档是 `gg-mac-mini` 主机与外部大容量存储阵列（`/Volumes/extdisk`）的**权威运维与系统重建规范**。当重装系统、迁移主机或重新配置硬件时，可直接依据本文档快速完成系统级能耗优化、防静默唤醒策略及媒体服务的端到端部署。

---

## 1. 硬件拓扑与核心目标

* **主机设备**：Mac mini (Apple Silicon)
* **外部存储设备**：
  * **硬盘规格**：两块 **14TB WD Red Pro 7200 RPM** 企业级机械硬盘（充氦盘）。
  * **硬盘柜**：双盘位硬盘柜（ASMedia USB 桥接控制器，ASM235CM）。
  * **阵列模式**：**AppleRAID 0 (Stripe)**，逻辑容量 28.0 TB，挂载于 `/Volumes/extdisk`。
  * **文件系统**：Mac OS Extended (Case-sensitive, Journaled HFS+)。
  * **Volume UUID**：`3DF1A047-9D24-3B78-82CB-420E76C3C671`
  * **RAID Set UUID**：`EC720DDE-3CD7-4B70-861D-9623AB313690`
* **维护核心目标**：
  * 7200 转企业级硬盘在短时间内频繁起停（Spindown / Spinup）会对马达和磁头造成机械应力与疲劳磨损。
  * **核心策略**：彻底消除系统后台（Finder、Spotlight、CacheDelete、媒体服务定时扫盘）的**无意义静默唤醒**，让机械硬盘在无业务读写时稳定深度休眠（Standby，启停频次目标 `< 3~5 次/天`）。

---

## 2. 系统层防唤醒核心配置清单（重装系统必做）

在干净安装的 macOS 上，系统默认的行为会高频唤醒外部机械硬盘（每天 30~50 次以上）。重装系统后**必须依次完成以下 4 项系统级配置**：

### 2.1. 关键配置：`/etc/fstab` 配置 `nobrowse` 挂载（阻断 Finder 与 CacheDelete）

* **原理与背景**：
  macOS 内部存在核心守护进程 `deleted`（CacheDelete 框架，受 SIP 保护）。每面前台使用 Mac、切换桌面或打开文件选择框时，Finder 会为了渲染外置磁盘的容量指示条与角标，向 `deleted` 发起 XPC 查询各扩展的可清理缓存，从而频繁唤醒机械硬盘。
  将该卷标记为 **`nobrowse`** 后，Finder 视其为后台专用卷，**彻底终止针对该卷的一切缓存与容量轮询**；同时底层 POSIX 路径 `/Volumes/extdisk` 保持完全正常读写，所有后台服务（Jellyfin、Radarr、Sonarr 等）完全无感知。

* **配置命令**：
  在 `/etc/fstab` 中追加配置（已在 `modules/media.nix` 激活脚本中自动化固化）：
  ```bash
  # 1. 确认该卷 UUID
  diskutil info /Volumes/extdisk | grep "Volume UUID"
  # 输出: Volume UUID: 3DF1A047-9D24-3B78-82CB-420E76C3C671

  # 2. 追加 nobrowse 规则至 /etc/fstab (挂载点填写 none，由 diskarbitrationd 动态接管 /Volumes/extdisk)
  echo "UUID=3DF1A047-9D24-3B78-82CB-420E76C3C671 none hfs rw,auto,nobrowse 0 0" | sudo tee -a /etc/fstab
  ```

* **即刻生效与验证**：
  ```bash
  # 1. 刷新挂载属性为 nobrowse
  sudo mount -u -o nobrowse /Volumes/extdisk

  # 2. 设置 macOS 隐藏卷标志（彻底消除文件选择器与访达图形残留）
  sudo chflags hidden /Volumes/extdisk

  # 3. 重启 Finder 释放旧的磁盘缓存状态
  killall Finder

  # 4. 验证挂载属性中包含 nobrowse
  mount | grep extdisk
  # 正确输出应包含: (hfs, local, journaled, nobrowse)
  ```

* **日常在 Finder 中按需访问的方法**：
  * 在终端随时执行：`open /Volumes/extdisk`
  * 或者在用户主目录下建立便捷访问软链接：
    ```bash
    ln -s /Volumes/extdisk/Movies ~/Movies/extdisk-movies
    ln -s /Volumes/extdisk/TV ~/Movies/extdisk-tv
    ```

---

### 2.2. 磁盘休眠时间调整为 30 分钟 (`disksleep 30`)

* **配置依据**：[`modules/system.nix`](../modules/system.nix) 中声明 `power.sleep.harddisk = 30;`
* **原理**：macOS 默认的 10 分钟休眠过于激进，若应用程序在 15~20 分钟内发生间歇性微量写入，会导致机械盘反复“刚睡下又被拉起”。设为 30 分钟可提供平稳的运行缓冲区。
* **即时生效命令**：
  ```bash
  sudo pmset -a disksleep 30
  # 验证当前生效值
  pmset -g | grep disksleep
  ```

---

### 2.3. 彻底禁用 Spotlight 索引与元数据扫描

* **配置依据**：[`modules/media.nix`](../modules/media.nix)
* **原理**：Spotlight 的 `mds` 和 `mdworker` 进程在检测到磁盘挂载或有新文件时，会强行遍历全盘建索引，必须彻底关闭。
* **执行命令**：
  ```bash
  touch /Volumes/extdisk/.metadata_never_index
  sudo /usr/bin/mdutil -i off /Volumes/extdisk
  # 验证生效状态
  /usr/bin/mdutil -s /Volumes/extdisk
  # 预期输出: Indexing and searching disabled.
  ```

---

### 2.4. Finder 桌面图标收敛

* **执行命令**：
  ```bash
  # 关闭桌面常驻外置硬盘图标
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  killall Finder
  ```

---

## 3. 媒体栈（Media Stack）防扫盘配置规范

后台媒体服务如果开启了实时目录监控或定时全量扫盘，将导致机械硬盘无法正常休眠。

### 3.1. Jellyfin
* **Web 控制台**：`http://localhost:8096` -> **控制台 (Dashboard)**
* **媒体库设置**：
  * 进入 **媒体库 (Libraries)** -> 编辑各影视库 -> **取消勾选“启用实时监控 (Enable Realtime Monitor)”**。
* **计划任务收敛**：
  * 进入 **计划任务 (Scheduled Tasks)**：
  * 下列涉及磁盘 I/O 的任务，**触发器全部移除（`Triggers: []`）**，改为仅手动触发：
    * 扫描媒体库 (Scan Media Library)
    * 媒体片段扫描 (Media Segment Scan)
    * 提取章节图片 (Extract Chapter Images)
    * 生成播放预览图 (Trickplay)
  * 系统维护任务（清理转码、清理缓存、数据库优化）集中收敛为：**每周日凌晨 03:00（Sunday 03:00）**。

### 3.2. Radarr & Sonarr
* **Web 控制台**：Radarr (`:7878`) / Sonarr (`:8989`)
* **核心防扫盘参数 (Media Management)**：
  * 进入 **Settings -> Media Management**：
    * **Rescan Series / Movie Folder after Analysis**: 设为 **`Never`**（官方源码已确认：设为 Never 后彻底跳过物理磁盘扫描，仅在内存与 SQLite 中比对 TMDB 元数据，零物理 I/O）。
    * **Change File Date**: 设为 **`None`**（不修改磁盘文件写入属性）。

### 3.3. Bazarr
* **部署状态**：**彻底移除不安装**。
* **原因**：Bazarr 的比对轮询会高频遍历视频目录，且现代播放端（Infuse、Jellyfin、PotPlayer 等）均具备即时在线字幕检索匹配能力。

---

## 4. 自动化备份与灾难恢复（Backup & Recovery）

### 4.1. 备份体系架构
* **备份目标**：`${HOME}/Google Drive/My Drive/MediaStack-Backups/`
* **定时载体**：launchd 用户代理 `org.nixos.media-backup`（每周日凌晨 03:00 自动执行）。
* **核心备份脚本**：[`scripts/backup-media.sh`](../scripts/backup-media.sh)
  * 通过 API 触发 Radarr、Sonarr、Prowlarr 在线配置导出；
  * 归档 SABnzbd 配置；
  * 执行 Jellyfin SQLite 在线安全热备（`.backup`）。

### 4.2. 运维指令速查
```bash
# 1. 立即手动执行一次全量热备
media-backup

# 2. 系统重装后的一键恢复配置
media-restore
```

### 4.3. GitHub 代码全量自动化镜像备份（GitHub Mirror Backup）
* **备份目标**：`/Volumes/extdisk/Backups/github/`
* **定时载体**：launchd 用户代理 `org.nixos.github-backup`（每周日凌晨 03:30 自动执行，紧随媒体维护窗口，避免硬盘产生二次起停循环）。
* **核心脚本**：[`scripts/backup-github.sh`](../scripts/backup-github.sh)
* **备份范围**：
  * GitHub 账号（`chen-gz`）下所有公开与私有仓库（Git Mirror 裸库镜像，全量保留全部分支、Tag、提交历史）。
  * 账号下全部 Gists 代码片段。
* **安全与权限**：
  * 通过 GPG 动态解密 `keys/github-token.gpg`，认证凭据在内存中通过 HTTP Basic 认证头传递，彻底杜绝本地 `.git/config` 泄漏明文 Token。
  * 自动在系统激活时（`postActivation`）保障 `/Volumes/extdisk/Backups/github` 的正确用户所有权（`guangzong:staff`）。

### 4.4. GitHub 备份运维与恢复速查
```bash
# 1. 手动立即触发全量增量镜像备份
github-backup

# 2. 查看最新一次备份的元数据报告
cat /Volumes/extdisk/Backups/github/latest_backup.json

# 3. 从镜像裸库恢复/克隆完整代码仓库
git clone /Volumes/extdisk/Backups/github/repos/<repo-name>.git <local-destination>

# 4. 从镜像恢复 Gist
git clone /Volumes/extdisk/Backups/github/gists/<gist-id>.git <local-destination>
```

---

## 5. SMART 健康监控与日常巡检标准

### 5.1. 关键健康指标参考

日常巡检使用 `smartctl` 重点关注以下关键属性：

| SMART ID | 属性名称 | 健康参考值 | 诊断说明 |
| :--- | :--- | :--- | :--- |
| **04** | `Start_Stop_Count` | `< 5 次/天` | 主轴电机启停计数。在配置 `nobrowse` 与防扫盘后应稳定在此区间 |
| **05** | `Reallocated_Sector_Ct` | **0** | 已重映射物理坏道数（必须严格为 0） |
| **09** | `Power_On_Hours` | 持续自增 | 累计通电运行小时数 |
| **193** | `Load_Cycle_Count` | `< 600,000` | 磁头收起归位次数（企业盘设计寿命 60 万次） |
| **194** | `Temperature_Celsius` | `< 50°C` | 7200 RPM 正常工作温度应在 38°C ~ 45°C |
| **197** | `Current_Pending_Sector`| **0** | 待映射扇区数（必须为 0） |
| **199** | `UDMA_CRC_Error_Count` | **0** | 接口通信错误计数（用于排查硬盘柜 SATA/USB 接口松动） |

### 5.2. 历史基准报告归档
所有历史基准数据存档于 `logs/` 目录：
* 初始基准 (2026-09-15)：[`logs/smartctl_report_20260915_1624.log`](../logs/smartctl_report_20260915_1624.log)
* 调优基准 (2026-09-20)：[`logs/smartctl_report_20260920_1211.log`](../logs/smartctl_report_20260920_1211.log)
* 持续巡检 (2026-09-22)：[`logs/smartctl_report_20260922_1006.log`](../logs/smartctl_report_20260922_1006.log)
* 最新巡检 (2026-09-24)：[`logs/smartctl_report_20260924_1306.log`](../logs/smartctl_report_20260924_1306.log)

### 5.3. 常用运维排查一条龙指令

```bash
# 1. 检查 AppleRAID 阵列在线状态
diskutil appleRAID list

# 2. 检查当前挂载状态与 nobrowse 属性
mount | grep extdisk

# 3. 检查系统休眠参数与 Spotlight 状态
pmset -g | grep disksleep
mdutil -s /Volumes/extdisk

# 4. 检查当前是否有物理 I/O 活动（验证 0 I/O 休眠）
iostat -d -c 2

# 5. 快速查看两块硬盘的 SMART 关键健康计数
smartctl -A /dev/disk6 | grep -E "Power_On_Hours|Start_Stop_Count|Load_Cycle_Count|Temperature|Reallocated"
smartctl -A /dev/disk7 | grep -E "Power_On_Hours|Start_Stop_Count|Load_Cycle_Count|Temperature|Reallocated"
```
