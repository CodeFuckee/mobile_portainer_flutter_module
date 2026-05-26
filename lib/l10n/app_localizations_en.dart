import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Docker Monitor';

  @override
  String get titleContainers => 'Containers';

  @override
  String get titleImages => 'Images';

  @override
  String get titleSettings => 'Settings';

  @override
  String get labelDockerApiUrl => 'Docker API URL';

  @override
  String get hintIpPort => 'http://ip:port';

  @override
  String get helperDockerApiUrl => 'e.g., http://10.0.2.2:2375 for Android Emulator';

  @override
  String get buttonSave => 'Save';

  @override
  String get msgSettingsSaved => 'Settings saved';

  @override
  String get msgNoContainers => 'No containers found';

  @override
  String get msgRetry => 'Retry';

  @override
  String msgCurrentApi(Object api) {
    return 'Current API: $api';
  }

  @override
  String get buttonRefresh => 'Refresh';

  @override
  String get labelLanguage => 'Language';

  @override
  String get optionSystem => 'System Default';

  @override
  String get optionEnglish => 'English';

  @override
  String get optionChinese => 'Chinese';

  @override
  String get labelApiKey => 'API Key';

  @override
  String get hintApiKey => 'Enter your API Key (optional)';

  @override
  String get helperApiKey => 'Required for some Portainer/Docker setups';

  @override
  String get labelStack => 'Stack';

  @override
  String get labelImage => 'Image';

  @override
  String get labelPorts => 'Ports';

  @override
  String get labelSearch => 'Search';

  @override
  String get hintSearch => 'Search containers...';

  @override
  String get labelStatusAll => 'all';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelFilterStatus => 'Filter by Status';

  @override
  String get labelFilterStack => 'Filter by Stack';

  @override
  String get actionStart => 'Start';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionKill => 'Kill';

  @override
  String get actionRestart => 'Restart';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get labelTimezone => 'Timezone';

  @override
  String get optionUtc => 'UTC';

  @override
  String get optionUtcPlus8 => 'UTC+8 (China)';

  @override
  String get optionUtcPlus9 => 'UTC+9 (Japan)';

  @override
  String get optionUtcMinus5 => 'UTC-5 (Eastern US)';

  @override
  String get optionUtcPlus1 => 'UTC+1 (Central Europe)';

  @override
  String get msgOperationNotAllowed => 'Operation not allowed for this container';

  @override
  String get sectionServers => 'Servers';

  @override
  String get buttonAddServer => 'Add Server';

  @override
  String get labelServerName => 'Server Name';

  @override
  String get msgServerAdded => 'Server added';

  @override
  String get msgServerUpdated => 'Server updated';

  @override
  String get msgServerCopied => 'Server copied';

  @override
  String get msgServerDeleted => 'Server deleted';

  @override
  String msgServerSwitched(Object name) {
    return 'Switched to $name';
  }

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDeleteAll => 'Delete All';

  @override
  String get msgConfirmDeleteAllContainers => 'Are you sure you want to delete all containers in this stack? This action cannot be undone.';

  @override
  String get labelActive => 'Active';

  @override
  String get titleDashboard => 'Dashboard';

  @override
  String get labelServerInfo => 'Server Info';

  @override
  String get labelTotal => 'Total';

  @override
  String get labelRunning => 'Running';

  @override
  String get labelStopped => 'Stopped';

  @override
  String get msgWsConnected => 'WebSocket Connected';

  @override
  String get msgWsDisconnected => 'WebSocket Disconnected';

  @override
  String get titlePullImage => 'Pull Image';

  @override
  String get labelImageName => 'Image Name';

  @override
  String get hintImageName => 'e.g., docker.1ms.run/emqx/emqx';

  @override
  String get labelTag => 'Tag';

  @override
  String get hintTag => 'e.g., latest';

  @override
  String get buttonPull => 'Pull';

  @override
  String get msgImageNameRequired => 'Image name cannot be empty';

  @override
  String get msgImagePullSuccess => 'Image pulled successfully';

  @override
  String msgImagePullFailed(Object error) {
    return 'Pull failed: $error';
  }

  @override
  String get tabDetails => 'Details';

  @override
  String get tabLogs => 'Logs';

  @override
  String get msgNoLogs => 'No logs available';

  @override
  String get msgLoadingLogs => 'Loading logs...';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabNetwork => 'Network';

  @override
  String get tabStorage => 'Storage';

  @override
  String get tabEnv => 'Env';

  @override
  String get tabFiles => 'Files';

  @override
  String get titleNetworks => 'Networks';

  @override
  String get hintSearchNetworks => 'Search networks...';

  @override
  String get labelDriver => 'Driver';

  @override
  String get labelScope => 'Scope';

  @override
  String get titleStacks => 'Stacks';

  @override
  String get hintSearchStacks => 'Search stacks...';

  @override
  String get titleVolumes => 'Volumes';

  @override
  String get hintSearchVolumes => 'Search volumes...';

  @override
  String get titleResources => 'Resources';

  @override
  String get titlePorts => 'Ports';

  @override
  String msgAvailablePorts(Object count) {
    return 'Available Ports: $count';
  }

  @override
  String get msgPortRange => 'Port Range';

  @override
  String get labelMountpoint => 'Mountpoint';

  @override
  String get labelCreated => 'Created At';

  @override
  String get labelOptions => 'Options';

  @override
  String get labelLabels => 'Labels';

  @override
  String get labelIgnoreSsl => 'Ignore SSL Verification';

  @override
  String get msgErrorLoadingFiles => 'Error loading files';

  @override
  String msgFileSelected(Object name, Object size) {
    return 'Selected file: $name ($size)';
  }

  @override
  String get labelMounted => 'Mounted';

  @override
  String get msgFileSaved => 'File saved successfully';

  @override
  String msgErrorSavingFile(Object error) {
    return 'Error saving file: $error';
  }

  @override
  String get labelInUse => 'In Use';

  @override
  String get msgContainerClosed => 'Container is closed, cannot access files';

  @override
  String get labelDownload => 'Download';

  @override
  String get labelShare => 'Share';

  @override
  String get msgDownloading => 'Downloading...';

  @override
  String get titleConfirmDelete => 'Confirm Delete';

  @override
  String get msgConfirmDeleteImage => 'Are you sure you want to delete this image?';

  @override
  String get titleNewVersion => 'New Version Available';

  @override
  String get msgNoUpdate => 'Your app is up to date';

  @override
  String get errCheckUpdate => 'Failed to check for updates';

  @override
  String get msgOpeningBrowserForDownload => 'Opening browser to download update...';

  @override
  String get errOpenDownloadUrl => 'Failed to open download link';

  @override
  String get actionUpdate => 'Update';

  @override
  String get labelGithub => 'GitHub Repository';

  @override
  String get buttonScanQr => 'Scan QR Code';

  @override
  String get msgScanSuccess => 'Scanned successfully';

  @override
  String get msgInvalidQr => 'Invalid QR format';

  @override
  String get buttonManualInput => 'Manual Input';

  @override
  String get titleRunContainer => 'Run Container';

  @override
  String get labelCommand => 'Command';

  @override
  String get hintCommand => 'e.g., docker run -d -p 80:80 nginx';

  @override
  String msgContainerStarted(Object id) {
    return 'Container started successfully: $id';
  }

  @override
  String msgRunContainerFailed(Object error) {
    return 'Failed to run container: $error';
  }

  @override
  String get actionRun => 'Run';

  @override
  String get labelUsedByContainers => 'Used By Containers';

  @override
  String get filterAll => 'All';

  @override
  String get filterInUse => 'In Use';

  @override
  String get filterUnused => 'Unused';

  @override
  String get msgConfirmDeleteVolume => 'Are you sure you want to delete this volume?';

  @override
  String get msgVolumeDeleted => 'Volume deleted successfully';

  @override
  String msgDeleteVolumeFailed(Object error) {
    return 'Failed to delete volume: $error';
  }

  @override
  String get titleNetworkDetails => 'Network Details';

  @override
  String get labelSubnet => 'Subnet';

  @override
  String get labelGateway => 'Gateway';

  @override
  String get labelInternal => 'Internal';

  @override
  String get labelAttachable => 'Attachable';

  @override
  String get labelIngress => 'Ingress';

  @override
  String get labelIPAM => 'IPAM';

  @override
  String get labelEnableIPv6 => 'Enable IPv6';

  @override
  String get titleEnvVars => 'Environment Variables';

  @override
  String get tabGlobal => 'Global';

  @override
  String get tabGroups => 'Groups';

  @override
  String get labelKey => 'Key';

  @override
  String get labelValue => 'Value';

  @override
  String get labelGroupName => 'Group Name';

  @override
  String get msgVarAdded => 'Variable added';

  @override
  String get msgGroupAdded => 'Group added';

  @override
  String get msgConfirmDelete => 'Are you sure you want to delete?';

  @override
  String get actionInsertEnvVars => 'Insert Env Vars';

  @override
  String get titleSelectEnvVars => 'Select Env Vars';

  @override
  String labelSelectedCount(Object count) {
    return '$count variables selected';
  }
}
