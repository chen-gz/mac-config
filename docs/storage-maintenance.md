# 外部存储与媒体栈能耗维护规范 (Storage & Media Stack Maintenance)

本文档记录 macOS (`gg-mac-mini`) 上外部企业级机械硬盘阵列（`/Volumes/extdisk`）的电源管理、媒体栈服务优化、备份运维与 SMART 监控维护规范。

---

## 1. 硬件拓扑与优化目标

* **硬件配置**：
  * 两块 **14TB WD Red Pro 7200 RPM** 企业级机械硬盘。
  * 通过双盘位硬盘柜（ASMedia USB 桥接控制器）接入 Mac Mini。
  * 组成 **AppleRAID 0 (Stripe)** 逻辑阵列卷（设备标识 `/dev/disk8`，成员盘为 `/dev/disk6` 与 `/dev/disk7`），挂载于 `/Volumes/extdisk`，容量 28.0 TB。
* **维护目标**：
  * 7200 转企业级硬盘在短时间内频繁启停（Spindown / Spinup Cycling）会对马达和磁头机械结构造成疲劳磨损。
  * 配置的核心目标是**消除后台无意义的静默唤醒**，让硬盘在无主动使用时稳定进入深度休眠（Standby）；而在活跃时段给予适当的运行缓冲，避免“刚睡下几分钟又被再次唤醒”。

---

## 2. 系统层电源策略与 Spotlight 屏蔽

### 2.1. 磁盘休眠时间调整为 30 分钟
* **配置位置**：[`modules/system.nix`](../modules/system.nix)
  ```nix
  power.sleep.harddisk = 30;
  ```
* **策略原理**：
  * macOS 默认的 10 分钟休眠过于激进，当应用发生相隔 15~20 分钟的微小写入时，会引起多次完整的起停循环。
  * 延长至 30 分钟后，硬盘在有间歇读写时保持连续运转，避免短时间内的二次加速起振；在真正闲置 30 分钟后切断供电停转。
* **即时生效命令**：
  ```bash
  sudo pmset -a disksleep 30
  ```

### 2.2. 彻底禁用 Spotlight 索引与扫描
* **配置位置**：[`modules/media.nix`](../modules/media.nix) 系统激活脚本中永久固化：
  ```bash
  if [ -d "/Volumes/extdisk" ]; then
    touch /Volumes/extdisk/.metadata_never_index 2>/dev/null || true
    /usr/bin/mdutil -i off /Volumes/extdisk 2>/dev/null || true
  fi
  ```
* **效果验证**：
  ```bash
  mdutil -s /Volumes/extdisk
  # 输出: Indexing and searching disabled.
  ```

### 2.3. /etc/fstab nobrowse 挂载策略（彻底阻断 Finder 与 CacheDelete 唤醒）
* **配置位置**：[`modules/media.nix`](../modules/media.nix) 系统激活脚本中永久固化，亦可参考完整重建指南 [`docs/server-maintenance.md`](server-maintenance.md)。
* **策略原理**：
  macOS 的 `deleted` 守护进程（CacheDelete）会在前台使用 Finder 或弹窗时自动探测已挂载磁盘的可清理空间。将该卷在 `/etc/fstab` 中标记为 `nobrowse` 后，Finder 视其为后台专用卷，彻底终止针对该卷的一切缓存与容量轮询；同时 `/Volumes/extdisk` 底层文件系统正常读写，Jellyfin、Radarr、Sonarr 等完全无感知。
* **规则配置**：
  ```bash
  echo "UUID=3DF1A047-9D24-3B78-82CB-420E76C3C671 none hfs rw,auto,nobrowse 0 0" | sudo tee -a /etc/fstab
  sudo mount -u -o nobrowse /Volumes/extdisk
  ```
* **验证效果**：
  ```bash
  mount | grep extdisk
  # 输出应包含: (..., nobrowse, ...)
  ```

---

## 3. 应用层服务（Media Stack）配置规范

后台媒体服务如果开启了实时目录监控或高频定时全盘扫盘，会成为机械硬盘无法休眠或频繁唤醒的主要根源。

### 3.1. Jellyfin（媒体播放与服务器）
* **Web 控制台**：`http://localhost:8096` -> **控制台 (Dashboard)** -> **计划任务 (Scheduled Tasks)**
* **外部硬盘高频任务处理**：
  下列涉及遍历 `/Volumes/extdisk` 的任务，**自动触发器已全部移除（`Triggers: []`）**，转为纯按需模式或手动扫描：
  * **扫描媒体库 (Scan Media Library)**：已移除每 12 小时间隔触发器。
  * **媒体片段扫描 (Media Segment Scan)**：已移除每 12 小时间隔触发器。
  * **提取章节图片 (Extract Chapter Images)**：已移除每日定时触发器。
  * **生成播放预览图 (Generate Trickplay Images)**：已移除每日定时触发器。
  * **音频正常化 (Audio Normalization)**：已移除每日触发器。
  * **下载缺失字幕 / 歌词**：已移除每日触发器。
* **系统维护任务收敛**：
  清理缓存、清理日志、清理转码目录、优化数据库等不触碰外部大容量视频的任务，已统一收敛为 **每周日凌晨 03:00（`WeeklyTrigger, Sunday 03:00`）** 集中执行。

### 3.2. Radarr & Sonarr（电影与电视剧索引）
* **Web 控制台**：
  * Radarr: `http://localhost:7878`
  * Sonarr: `http://localhost:8989`
* **Media Management 设置**：
  在 **Settings -> Media Management** 中必须保持如下配置：
  * **Rescan Series / Movie Folder after Analysis**: 设为 **`Never`**（分析视频流信息后不重新扫盘）。
  * **Change File Date**: 设为 **`None`**（不修改磁盘文件属性）。
* **刷新与健康检查任务周期（SQLite 数据库维护）**：
  * **健康检查与根目录空间巡检 (CheckHealthCommand)**：
    默认每 6 小时（360 分钟）向 `/Volumes/extdisk` 根目录发起空间检测，会唤醒休眠中的机械硬盘。**已统一收敛为 7 天（10080 分钟）一次**：
    ```bash
    sqlite3 "$HOME/Library/Application Support/Radarr/radarr.db" \
      "UPDATE ScheduledTasks SET Interval = 10080 WHERE TypeName = 'NzbDrone.Core.HealthCheck.CheckHealthCommand';"

    sqlite3 "$HOME/.config/Sonarr/sonarr.db" \
      "UPDATE ScheduledTasks SET Interval = 10080 WHERE TypeName = 'NzbDrone.Core.HealthCheck.CheckHealthCommand';"

    launchctl kickstart -k gui/$(id -u)/org.nixos.radarr
    launchctl kickstart -k gui/$(id -u)/org.nixos.sonarr
    ```
  * **全库文件刷新 (RefreshMovie / RefreshSeries)**：
    默认每日执行一次（`RefreshMovieCommand` 为 1440 分钟，`RefreshSeriesCommand` 为 720 分钟）。如需进一步收敛为 7 天执行一次（10080 分钟）：
    ```bash
    # Radarr 改为 7 天刷新一次
    sqlite3 "$HOME/Library/Application Support/Radarr/radarr.db" \
      "UPDATE ScheduledTasks SET Interval = 10080 WHERE TypeName = 'NzbDrone.Core.Movies.Commands.RefreshMovieCommand';"

    # Sonarr 改为 7 天刷新一次
    sqlite3 "$HOME/.config/Sonarr/sonarr.db" \
      "UPDATE ScheduledTasks SET Interval = 10080 WHERE TypeName = 'NzbDrone.Core.Tv.Commands.RefreshSeriesCommand';"
    ```

### 3.3. Bazarr（字幕同步管理）
* **状态**：**已彻底移除**。
* **原因**：Bazarr 默认每小时或每日向 Radarr/Sonarr 对比字幕并在磁盘比对视频文件，无法避免后台唤醒。目前播放端（如 Jellyfin/Infuse/PotPlayer）均具备即时在线字幕匹配能力，无需后台驻留守护进程。

---

## 4. 备份与灾备恢复流程

### 4.1. 自动化定时备份
* **执行时间**：每周日凌晨 03:00。
* **服务载体**：launchd 用户代理 `org.nixos.media-backup`。
* **备份脚本**：[`scripts/backup-media.sh`](../scripts/backup-media.sh)
* **备份目标**：`${HOME}/Google Drive/My Drive/MediaStack-Backups/`
* **收敛流程（5 步）**：
  1. `[1/5]` 通过 API 触发 Radarr 核心配置备份。
  2. `[2/5]` 通过 API 触发 Sonarr 核心配置备份。
  3. `[3/5]` 通过 API 触发 Prowlarr 核心配置备份。
  4. `[4/5]` 备份 SABnzbd 配置文件 `sabnzbd.ini`。
  5. `[5/5]` 执行 Jellyfin 在线热备（`jellyfin.db` SQLite 在线备份 + `config/` 目录同步）。

### 4.2. 手动运维指令
在终端中可直接使用 Fish Shell 内置别名：
* **立即备份**：执行 `media-backup`
* **一键恢复**：执行 `media-restore`（通过 [`scripts/restore-media.sh`](../scripts/restore-media.sh) 将 Google Drive 中的最新备份解压恢复到对应系统路径）

### 4.3. GitHub 代码全量自动化镜像备份（外部存储阵列容灾）
* **执行时间**：每周日凌晨 03:05。
* **能耗协同**：紧随 03:00 媒体库与数据库维护窗口集中写入，在机械硬盘 30 分钟休眠窗口期内完成，**彻底杜绝额外的磁头启停循环（Spindown/Spinup Cycling）**。
* **服务载体**：launchd 用户代理 `org.nixos.github-backup`。
* **备份脚本**：[`scripts/backup-github.sh`](../scripts/backup-github.sh)
* **备份目标**：`/Volumes/extdisk/Backups/github/`
* **备份内容**：
  * GitHub 账号（`chen-gz`）下所有公开与私有代码仓库（Git Mirror 镜像裸库，包含所有分支、Tag、提交树）。
  * 账号下全部 Gists 代码片段。
* **安全与权限保障**：
  * 通过 GPG 动态解密 `keys/github-token.gpg`，认证头通过 HTTP Basic Auth 动态注入内存，磁盘 `.git/config` 零明文令牌暴露。
  * 由备份脚本（`scripts/backup-github.sh`）按需创建与管理备份目录，避免系统部署（`deploy`）遍历外部磁盘产生不必要的机械唤醒与 TCC 权限拦截。

### 4.4. GitHub 备份与恢复指令速查
```bash
# 1. 随时手动触发增量同步
github-backup

# 2. 查看最新备份状态及统计报告
cat /Volumes/extdisk/Backups/github/latest_backup.json

# 3. 灾难恢复：从本地镜像裸库克隆恢复仓库
git clone /Volumes/extdisk/Backups/github/repos/<repo-name>.git <local-dir>

# 4. 灾难恢复：从本地镜像克隆恢复 Gist
git clone /Volumes/extdisk/Backups/github/gists/<gist-id>.git <local-dir>
```

---

## 5. SMART 健康监控与日常巡检

### 5.1. 关键指标基准表
系统历史基准文件归档于 `logs/` 目录：
* 初始基准：[`logs/smartctl_report_20260915_1624.log`](../logs/smartctl_report_20260915_1624.log)
* 调优后基准：[`logs/smartctl_report_20260920_1211.log`](../logs/smartctl_report_20260920_1211.log)
* 持续巡检归档：[`logs/smartctl_report_20260922_1006.log`](../logs/smartctl_report_20260922_1006.log)
* 周期巡检归档：[`logs/smartctl_report_20260924_1306.log`](../logs/smartctl_report_20260924_1306.log)
* 最新巡检归档：[`logs/smartctl_report_20260930_1300.log`](../logs/smartctl_report_20260930_1300.log)

日常巡检重点关注以下 SMART 属性：

| SMART ID | 属性名称 | 健康参考值 | 说明 |
| :--- | :--- | :--- | :--- |
| **04** | `Start_Stop_Count` | 关注增量速率 | 主轴启停计数。优化后理想速率为 `< 5 次/天` |
| **05** | `Reallocated_Sector_Ct` | **0** | 已重映射坏道数（必须为 0） |
| **09** | `Power_On_Hours` | - | 累计通电小时数 |
| **193** | `Load_Cycle_Count` | `< 600,000` | 磁头收起归位次数（企业盘设计寿命约 60 万次） |
| **194** | `Temperature_Celsius` | `< 55°C` | 7200 RPM 正常工作温度在 38°C ~ 50°C 之间 |
| **197** | `Current_Pending_Sector`| **0** | 待映射扇区数（必须为 0） |
| **199** | `UDMA_CRC_Error_Count` | **0** | 接口传输错误（用于排查线缆和 USB 硬盘柜接口松动） |

### 5.2. 常用巡检指令速查

```bash
# 1. 查看外部 RAID 状态是否正常在线
diskutil appleRAID list

# 2. 查看当前系统休眠参数（确认 disksleep 为 30）
pmset -g | grep disksleep

# 3. 检查是否有系统进程唤醒磁盘
pmset -g log | grep -i "disk" | tail -n 20

# 4. 实时查看外部磁盘读写活动（验证是否处于 0 I/O 休眠）
iostat -d -c 2

# 5. 查看两块硬盘的实时 SMART 关键计数
smartctl -A /dev/disk6 | grep -E "Power_On_Hours|Start_Stop_Count|Load_Cycle_Count|Temperature"
smartctl -A /dev/disk7 | grep -E "Power_On_Hours|Start_Stop_Count|Load_Cycle_Count|Temperature"
```
