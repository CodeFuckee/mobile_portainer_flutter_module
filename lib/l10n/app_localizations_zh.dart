// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Docker 监控';

  @override
  String get titleContainers => '容器';

  @override
  String get titleImages => '镜像';

  @override
  String get titleSettings => '设置';

  @override
  String get labelDockerApiUrl => 'Docker API 地址';

  @override
  String get hintIpPort => 'http://ip:port';

  @override
  String get helperDockerApiUrl => '例如：Android 模拟器使用 http://10.0.2.2:2375';

  @override
  String get buttonSave => '保存';

  @override
  String get msgSettingsSaved => '设置已保存';

  @override
  String get msgNoContainers => '暂无容器';

  @override
  String get msgRetry => '重试';

  @override
  String msgCurrentApi(Object api) {
    return '当前 API：$api';
  }

  @override
  String get buttonRefresh => '刷新';

  @override
  String get labelLanguage => '语言';

  @override
  String get optionSystem => '系统默认';

  @override
  String get optionEnglish => 'English';

  @override
  String get optionChinese => '中文';

  @override
  String get labelApiKey => 'API 密钥';

  @override
  String get hintApiKey => '输入 API 密钥（可选）';

  @override
  String get helperApiKey => '某些 Portainer/Docker 配置需要此项';

  @override
  String get labelStack => '应用栈';

  @override
  String get labelImage => '镜像';

  @override
  String get labelPorts => '端口';

  @override
  String get labelSearch => '搜索';

  @override
  String get hintSearch => '搜索容器...';

  @override
  String get labelStatusAll => '全部';

  @override
  String get labelStatus => '状态';

  @override
  String get labelFilterStatus => '按状态过滤';

  @override
  String get labelFilterStack => '按堆栈过滤';

  @override
  String get actionStart => '启动';

  @override
  String get actionStop => '停止';

  @override
  String get actionKill => '强制停止';

  @override
  String get actionRestart => '重启';

  @override
  String get actionPause => '暂停';

  @override
  String get actionResume => '恢复';

  @override
  String get actionRemove => '删除';

  @override
  String get actionCancel => '取消';

  @override
  String get labelTimezone => '时区';

  @override
  String get optionUtc => 'UTC';

  @override
  String get optionUtcPlus8 => 'UTC+8 (中国)';

  @override
  String get optionUtcPlus9 => 'UTC+9 (日本)';

  @override
  String get optionUtcMinus5 => 'UTC-5 (美东)';

  @override
  String get optionUtcPlus1 => 'UTC+1 (中欧)';

  @override
  String get msgOperationNotAllowed => '不允许对该容器进行操作';

  @override
  String get sectionServers => '服务器列表';

  @override
  String get sectionOther => '其他设置';

  @override
  String get buttonAddServer => '添加服务器';

  @override
  String get hintAddServer => '点击添加 Docker 服务器';

  @override
  String get labelServerName => '服务器名称';

  @override
  String get msgServerAdded => '已添加服务器';

  @override
  String get msgServerUpdated => '已更新服务器';

  @override
  String get msgServerCopied => '服务器已复制';

  @override
  String get msgServerDeleted => '已删除服务器';

  @override
  String msgServerSwitched(Object name) {
    return '已切换到 $name';
  }

  @override
  String get actionEdit => '编辑';

  @override
  String get actionCopy => '复制';

  @override
  String get actionShow => '显示';

  @override
  String get actionHide => '隐藏';

  @override
  String get actionDelete => '删除';

  @override
  String get actionDeleteAll => '全部删除';

  @override
  String get msgConfirmDeleteAllContainers => '确定要删除该应用栈下的所有容器吗？此操作无法撤销。';

  @override
  String get labelActive => '当前使用';

  @override
  String get titleDashboard => '概览';

  @override
  String get labelServerInfo => '服务器信息';

  @override
  String get labelTotal => '总计';

  @override
  String get labelRunning => '运行中';

  @override
  String get labelStopped => '已停止';

  @override
  String get msgWsConnected => 'WebSocket 已连接';

  @override
  String get msgWsDisconnected => 'WebSocket 已断开';

  @override
  String get titlePullImage => '拉取镜像';

  @override
  String get labelImageName => '镜像名称';

  @override
  String get hintImageName => '例如 docker.1ms.run/emqx/emqx';

  @override
  String get labelTag => 'Tag';

  @override
  String get hintTag => '例如 latest';

  @override
  String get buttonPull => '拉取';

  @override
  String get msgImageNameRequired => '镜像名称不能为空';

  @override
  String get msgImagePullSuccess => '镜像拉取成功';

  @override
  String msgImagePullFailed(Object error) {
    return '拉取失败: $error';
  }

  @override
  String get tabDetails => '详情';

  @override
  String get tabLogs => '日志';

  @override
  String get msgNoLogs => '暂无日志';

  @override
  String get msgLoadingLogs => '加载日志中...';

  @override
  String get tabOverview => '概览';

  @override
  String get tabNetwork => '网络';

  @override
  String get tabStorage => '存储';

  @override
  String get tabEnv => '环境';

  @override
  String get tabFiles => '文件';

  @override
  String get titleNetworks => '网络';

  @override
  String get hintSearchNetworks => '搜索网络...';

  @override
  String get labelDriver => '驱动';

  @override
  String get labelScope => '范围';

  @override
  String get titleStacks => '应用栈';

  @override
  String get hintSearchStacks => '搜索应用栈...';

  @override
  String get titleVolumes => '存储卷';

  @override
  String get hintSearchVolumes => '搜索存储卷...';

  @override
  String get titleResources => '资源';

  @override
  String get titlePorts => '端口';

  @override
  String msgAvailablePorts(Object count) {
    return '可用端口数：$count';
  }

  @override
  String get msgPortRange => '端口范围';

  @override
  String get labelMountpoint => '挂载点';

  @override
  String get labelCreated => '创建时间';

  @override
  String get labelOptions => '选项';

  @override
  String get labelLabels => '标签';

  @override
  String get labelIgnoreSsl => '忽略 SSL 验证';

  @override
  String get msgErrorLoadingFiles => '加载文件失败';

  @override
  String msgFileSelected(Object name, Object size) {
    return '已选择文件: $name ($size)';
  }

  @override
  String get labelMounted => '已挂载';

  @override
  String get msgFileSaved => '文件保存成功';

  @override
  String msgErrorSavingFile(Object error) {
    return '保存文件失败: $error';
  }

  @override
  String get labelInUse => '已使用';

  @override
  String get msgContainerClosed => '容器已关闭，无法获取容器内文件';

  @override
  String get labelDownload => '下载';

  @override
  String get labelShare => '分享';

  @override
  String get msgDownloading => '下载中...';

  @override
  String get titleConfirmDelete => '确认删除';

  @override
  String get msgConfirmDeleteImage => '确定要删除此镜像吗？';

  @override
  String get titleNewVersion => '发现新版本';

  @override
  String get msgNoUpdate => '当前已是最新版本';

  @override
  String get errCheckUpdate => '检查更新失败';

  @override
  String get msgOpeningBrowserForDownload => '正在打开浏览器下载安装包...';

  @override
  String get errOpenDownloadUrl => '无法打开下载链接';

  @override
  String get actionUpdate => '立即更新';

  @override
  String get labelGithub => 'GitHub 仓库';

  @override
  String get buttonScanQr => '扫描二维码';

  @override
  String get msgScanSuccess => '扫码成功';

  @override
  String get msgInvalidQr => '二维码格式无效';

  @override
  String get buttonManualInput => '手动输入';

  @override
  String get titleRunContainer => '运行容器';

  @override
  String get labelCommand => '命令';

  @override
  String get hintCommand => '例如：docker run -d -p 80:80 nginx';

  @override
  String msgContainerStarted(Object id) {
    return '容器启动成功：$id';
  }

  @override
  String msgRunContainerFailed(Object error) {
    return '运行容器失败：$error';
  }

  @override
  String get actionRun => '运行';

  @override
  String get labelUsedByContainers => '被容器使用';

  @override
  String get filterAll => '全部';

  @override
  String get filterInUse => '使用中';

  @override
  String get filterUnused => '未使用';

  @override
  String get msgConfirmDeleteVolume => '确定要删除此存储卷吗？';

  @override
  String get msgVolumeDeleted => '存储卷删除成功';

  @override
  String msgDeleteVolumeFailed(Object error) {
    return '删除存储卷失败: $error';
  }

  @override
  String get titleNetworkDetails => '网络详情';

  @override
  String get labelSubnet => '子网';

  @override
  String get labelGateway => '网关';

  @override
  String get labelInternal => '内部';

  @override
  String get labelAttachable => '可附加';

  @override
  String get labelIngress => '入口';

  @override
  String get labelIPAM => 'IPAM';

  @override
  String get labelEnableIPv6 => '启用 IPv6';

  @override
  String get titleEnvVars => '环境变量';

  @override
  String get tabGlobal => '全局';

  @override
  String get tabGroups => '组';

  @override
  String get labelKey => '键';

  @override
  String get labelValue => '值';

  @override
  String get labelGroupName => '组名';

  @override
  String get msgVarAdded => '变量已添加';

  @override
  String get msgGroupAdded => '组已添加';

  @override
  String get msgConfirmDelete => '确定要删除吗？';

  @override
  String get actionInsertEnvVars => '插入环境变量';

  @override
  String get titleSelectEnvVars => '选择环境变量';

  @override
  String labelSelectedCount(Object count) {
    return '已选 $count 个变量';
  }

  @override
  String get labelMore => '更多';

  @override
  String get titleLogin => '登录';

  @override
  String get labelUsername => '用户名';

  @override
  String get labelPassword => '密码';

  @override
  String get hintUsername => '请输入用户名';

  @override
  String get hintPassword => '请输入密码';

  @override
  String get btnLogin => '登录';

  @override
  String get msgLoginFailed => '登录失败，请检查您的凭据';

  @override
  String get msgConnecting => '正在连接...';

  @override
  String get btnLogout => '退出登录';

  @override
  String get titleApiKeys => 'API 密钥管理';

  @override
  String get labelApiKeyName => '密钥名称';

  @override
  String get hintApiKeyName => '输入密钥名称';

  @override
  String get labelApiKeyValue => '密钥值';

  @override
  String get hintApiKeyValue => '留空则由后端自动生成';

  @override
  String get msgApiKeyCreated => 'API 密钥已创建';

  @override
  String get msgApiKeyDeleted => 'API 密钥已删除';

  @override
  String get msgApiKeyCopied => 'API 密钥已复制到剪贴板';

  @override
  String get msgNoApiKeys => '暂无 API 密钥';

  @override
  String get actionCreateKey => '创建密钥';

  @override
  String get labelCreatedAt => '创建时间';

  @override
  String get labelExpiresAt => '过期时间';

  @override
  String get labelNever => '永不过期';

  @override
  String get msgConfirmDeleteApiKey => '确定要删除此 API 密钥吗？';

  @override
  String get msgNoContainerSelected => '选择一个容器查看详情';
}
