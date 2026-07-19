// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Pomu';

  @override
  String get duplicateCleanupTitle => '清理重复照片';

  @override
  String get later => '稍后';

  @override
  String get restorePurchase => '恢复购买';

  @override
  String get oneTimePurchase => '这是一次性购买，不是订阅。';

  @override
  String get paymentThroughApple => '付款将通过 Apple ID 进行。';

  @override
  String get duplicateIntroTitle => '先帮你找出\n看起来相似的照片。';

  @override
  String get duplicateIntroDescription => '现在不会删除任何照片，只会显示保留照片和删除候选。';

  @override
  String get duplicateSavingShort => '正在保存结果...';

  @override
  String get duplicateAnalyzingShort => '正在分析...';

  @override
  String get duplicateScanAgain => '重新扫描';

  @override
  String get duplicateFindCandidates => '查找重复照片';

  @override
  String get loading => '正在加载...';

  @override
  String get duplicateLoadMore => '查看更多重复照片';

  @override
  String get duplicateRestoringLastResult => '正在加载上次扫描结果。';

  @override
  String get duplicateSavingResult => '正在保存扫描结果...';

  @override
  String get duplicateReanalyzing => '正在重新分析重复照片...';

  @override
  String get duplicateSavingSafely => '正在安全保存扫描结果。';

  @override
  String get duplicateFindingCandidates => '正在查找重复候选。';

  @override
  String get duplicateContinueSoon => '稍后即可继续整理。';

  @override
  String get duplicateMayTakeTime => '照片较多时可能需要一些时间。';

  @override
  String get duplicateKeeperMinimum => '至少保留一张照片。';

  @override
  String get purchaseCompletedContinueDelete => '购买完成，将继续删除。';

  @override
  String get deleteCanceledOrFailed => '删除已取消或失败。';

  @override
  String get deletePreparation => '确认删除';

  @override
  String get deletedPhotosMoveToRecentlyDeleted => '删除的照片会移到“最近删除”。';

  @override
  String get cancel => '取消';

  @override
  String get unableToCheckSize => '无法检查容量';

  @override
  String get noPhotosToDelete => '没有可删除的照片';

  @override
  String get keep => '✓ 保留';

  @override
  String get deleteCandidate => '删除候选';

  @override
  String get noRemainingDuplicateCandidates => '没有剩余的重复候选';

  @override
  String get noAnalysisResult => '暂无分析结果';

  @override
  String get scanAgainIfNewPhotos => '添加新照片后请重新扫描。';

  @override
  String get tapFindCandidatesGuide => '点击“查找重复照片”扫描照片图库。';

  @override
  String get duplicateSavingWait => '正在保存扫描结果，请稍候。';

  @override
  String get duplicateAnalyzingWait => '正在分析重复照片，请稍候。';

  @override
  String duplicateLoadLastResultError(String error) {
    return '无法加载上次扫描结果：$error';
  }

  @override
  String duplicateLoadMoreError(String error) {
    return '无法加载更多重复候选：$error';
  }

  @override
  String duplicateAnalysisError(String error) {
    return '分析重复照片时出现问题：$error';
  }

  @override
  String duplicateSaveDeleteResultError(String error) {
    return '保存删除结果时出现问题：$error';
  }

  @override
  String duplicateProgress(int percent, int current, int total) {
    return '$percent% · 正在分析 $current / $total 组';
  }

  @override
  String duplicateSummaryPartial(int total, int visible, int deleteCount) {
    return '共 $total 组重复候选\n当前显示 $visible 组 · 删除候选 $deleteCount 张';
  }

  @override
  String duplicateSummaryFull(int total, int deleteCount) {
    return '$total 组重复候选\n删除候选 $deleteCount 张';
  }

  @override
  String freeDeleteCompleted(int count) {
    return '已删除 $count 张照片，并使用了首次免费整理。';
  }

  @override
  String deleteMovedToRecentlyDeleted(int count) {
    return '已将 $count 张照片移到“最近删除”。';
  }

  @override
  String deleteCandidatesReview(int count) {
    return '请再次确认要删除的 $count 张照片。';
  }

  @override
  String estimatedSpace(String size) {
    return '预计可释放空间：$size';
  }

  @override
  String deleteCount(int count) {
    return '删除 $count 张';
  }

  @override
  String duplicateCandidateCount(int count) {
    return '$count 张重复候选';
  }

  @override
  String keeperAndDeleteCount(int keepCount, int deleteCount) {
    return '保留 $keepCount 张 · 删除候选 $deleteCount 张';
  }

  @override
  String deletePreparationCount(int count) {
    return '确认删除（$count 张）';
  }

  @override
  String get homeHeroTitle => '整理 iPhone 照片，\n释放更多存储空间';

  @override
  String get homeHeroSubtitle => '查找重复照片和不需要的文件，\n安全地完成整理。';

  @override
  String get homeCleanupSectionTitle => '清理';

  @override
  String get homeCleanupSectionSubtitle => '查看占用存储空间的照片和视频。';

  @override
  String get homeScreenshotCleanupTitle => '清理截图';

  @override
  String get homeScreenshotCleanupDescription => '集中查看并清理旧截图。';

  @override
  String get homeLargeVideoCleanupTitle => '清理大视频';

  @override
  String get homeLargeVideoCleanupDescription => '按大小查看最占空间的视频。';

  @override
  String get homeAlbumSectionTitle => '创建相册';

  @override
  String get homeAlbumSectionSubtitle => '按照你选择的条件将照片整理成相册。';

  @override
  String get homeDateTimeAlbumTitle => '按日期与时间创建相册';

  @override
  String get homeDateTimeAlbumDescription => '选择日期范围和时间段来创建相册。';

  @override
  String get homeAutoClassificationTitle => '照片自动分类';

  @override
  String get homeAutoClassificationDescription => '分析照片并整理到不同主题相册中。';

  @override
  String get available => '可用';

  @override
  String get beta => '测试版';

  @override
  String get settings => '设置';

  @override
  String get analysisComplete => '分析完成';

  @override
  String get availableNow => '现在可用';

  @override
  String get homeDuplicateLoading => '正在加载重复照片信息。';

  @override
  String get homeDuplicateBeforeScanDescription => '在照片图库中查找重复照片，\n查看可以释放多少空间。';

  @override
  String get homeDuplicateCleanDescription => '目前没有需要清理的重复照片。\n你的照片图库很整洁。';

  @override
  String get homeDuplicateHasCandidatesDescription => '查找并清理相似照片。';

  @override
  String get homeFindDuplicates => '查找重复照片';

  @override
  String get homeCleanDuplicates => '清理重复照片';

  @override
  String get homeStartFirstScan => '开始首次扫描';

  @override
  String get homeFirstScanDescription => '不会删除任何照片，\n我们会先找出重复候选。';

  @override
  String get homeNoDuplicatesTitle => '没有需要清理的重复照片';

  @override
  String get homeNoDuplicatesDescription => '你的照片图库目前很整洁。';

  @override
  String homeGroupCount(int count) {
    return '$count 组';
  }

  @override
  String homeDeleteCandidateCount(int count) {
    return '$count 张删除候选';
  }

  @override
  String get homeReclaimableBeforeDelete => '删除前可以查看预计可释放空间。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsPhotoCleanupSectionTitle => '照片清理';

  @override
  String get settingsPhotoCleanupSectionSubtitle => '管理已保存的扫描结果。';

  @override
  String get settingsResetDuplicateTitle => '重置重复照片扫描结果';

  @override
  String get settingsResetDuplicateSubtitle => '清除已保存的结果和已处理记录，然后重新扫描。';

  @override
  String get settingsAlbumSectionTitle => '相册';

  @override
  String get settingsAlbumSectionSubtitle => '设置自动创建的相册名称。';

  @override
  String get settingsAutoAlbumNameTitle => '自动分类相册名称';

  @override
  String get settingsAutoAlbumNameSubtitle => '更改照片自动分类使用的相册名称。';

  @override
  String get settingsAppSectionTitle => '应用设置';

  @override
  String get settingsAppSectionSubtitle => '查看 Pomu 的基本设置。';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageSubtitle => '使用 iPhone 设置中为 Pomu 选择的语言。';

  @override
  String get settingsInfoSectionTitle => '应用信息';

  @override
  String get settingsInfoSectionSubtitle => '查看有关 Pomu 的信息。';

  @override
  String get settingsPrivacyPolicyTitle => '隐私政策';

  @override
  String get settingsPrivacyPolicySubtitle => '查看个人信息的处理方式。';

  @override
  String get settingsTermsTitle => '使用条款';

  @override
  String get settingsTermsSubtitle => '查看服务使用条款。';

  @override
  String get settingsContactTitle => '联系我们';

  @override
  String get settingsContactSubtitle => '咨询应用使用中的问题。';

  @override
  String get settingsAppVersionTitle => '应用版本';

  @override
  String get comingSoon => '即将推出';

  @override
  String get settingsResetDialogTitle => '要重置扫描结果吗？';

  @override
  String get settingsResetDialogDescription => '清除已保存的重复组和已处理记录，\n然后从头开始重新扫描。';

  @override
  String get settingsResetNoticeResolvedGroups => '之前处理过的组可能会再次出现。';

  @override
  String get settingsResetNoticePhotosSafe => 'iPhone 中的照片不会被删除或更改。';

  @override
  String get settingsResetNoticePurchaseKept => '购买记录和免费使用记录会保留。';

  @override
  String get settingsResetAction => '重置扫描结果';

  @override
  String get settingsResetSuccess => '已重置重复照片扫描结果。';

  @override
  String get settingsResetFailure => '无法重置结果，请稍后再试。';

  @override
  String get purchaseLifetimeBadge => '一次购买，永久使用';

  @override
  String get purchaseTitle => '继续使用\n重复照片清理';

  @override
  String get purchaseDescription => '首次重复照片组已免费清理。\n现在可以无限制继续整理。';

  @override
  String get purchaseLoadingProduct => '正在检查商品信息';

  @override
  String get purchaseOneTimeNoExtraCharge => '一次性付款 · 无额外费用';

  @override
  String get purchaseBenefitLifetimeTitle => '永久使用';

  @override
  String get purchaseBenefitLifetimeDescription => '只需付款一次';

  @override
  String get purchaseBenefitUnlimitedTitle => '无限清理';

  @override
  String get purchaseBenefitUnlimitedDescription => '不限制照片组数量';

  @override
  String get purchaseBenefitRestoreTitle => '恢复购买';

  @override
  String get purchaseBenefitRestoreDescription => '重新安装后仍可恢复';

  @override
  String get purchaseBenefitNoSubscriptionTitle => '无需订阅';

  @override
  String get purchaseBenefitNoSubscriptionDescription => '无需每月付款';

  @override
  String get purchaseLoadFailed => '无法加载商品信息，请稍后重试。';

  @override
  String get purchaseReloadProduct => '重新加载商品信息';

  @override
  String get purchaseRestoring => '正在检查购买记录。';

  @override
  String get purchaseRestoringShort => '正在检查购买记录...';

  @override
  String purchaseWithPrice(String price) {
    return '以 $price 永久使用';
  }

  @override
  String get screenshotLoadFailed => '无法加载截图。';

  @override
  String get screenshotDeleteFailed => '无法删除截图。';

  @override
  String screenshotDeletedSuccess(int count) {
    return '已将 $count 张截图移到“最近删除”。';
  }

  @override
  String get screenshotDeletePreparationTitle => '确认删除截图';

  @override
  String screenshotDeleteReview(int count) {
    return '请确认选中的 $count 张截图。';
  }

  @override
  String get screenshotMoveToRecentlyDeleted => '删除的项目会移到“照片”中的“最近删除”。';

  @override
  String get screenshotDeselectAll => '取消全选';

  @override
  String get screenshotSelectAll => '全选';

  @override
  String get deleting => '正在删除...';

  @override
  String get screenshotSelectToDelete => '请选择要删除的截图';

  @override
  String screenshotDeleteSelected(int count) {
    return '删除选中的 $count 张';
  }

  @override
  String screenshotTotalCount(int count) {
    return '$count 张截图';
  }

  @override
  String get screenshotSelectToDeleteWithPeriod => '请选择要删除的截图。';

  @override
  String screenshotSelectedCount(int count) {
    return '已选择 $count 张。';
  }

  @override
  String get photoPermissionRequiredTitle => '需要照片访问权限';

  @override
  String get screenshotPermissionDescription => '如需查看并清理截图，\n请允许访问照片图库。';

  @override
  String get openSettings => '打开设置';

  @override
  String get screenshotLimitedAccessDescription =>
      'Pomu 目前只能访问所选照片。如需查看所有截图，请添加更多照片。';

  @override
  String get addPhotos => '添加';

  @override
  String get screenshotEmptyTitle => '没有需要清理的截图';

  @override
  String get screenshotEmptyDescription => '照片图库中没有截图，\n或当前没有可访问的截图。';

  @override
  String get videoLoadFailed => '无法加载视频。';

  @override
  String videoDeletedSuccess(int count) {
    return '已将 $count 个视频移到“最近删除”。';
  }

  @override
  String get videoDeleteFailed => '无法删除视频。';

  @override
  String get videoLoadingOriginal => '正在加载视频。';

  @override
  String get videoOriginalLoadFailed => '无法加载视频原始文件。';

  @override
  String get videoDeletePreparationTitle => '确认删除视频';

  @override
  String videoDeleteReview(int count) {
    return '请确认选中的 $count 个视频。';
  }

  @override
  String get videoMoveToRecentlyDeleted => '删除的视频会移到“照片”中的“最近删除”。';

  @override
  String videoDeleteCount(int count) {
    return '删除 $count 个';
  }

  @override
  String get videoSelectToDelete => '请选择要删除的视频';

  @override
  String videoDeleteSelectedWithSize(int count, String size) {
    return '删除 $count 个 · $size';
  }

  @override
  String get videoFindingLargeVideos => '正在查找大视频';

  @override
  String videoCheckingSizes(int current, int total) {
    return '正在检查容量：$current / $total';
  }

  @override
  String get videoLoadingList => '正在加载视频列表。';

  @override
  String get videoMayTakeTime => '视频较多或存储在 iCloud 中时，可能需要更长时间。';

  @override
  String videoSummary(int count, String size) {
    return '$count 个视频 · $size';
  }

  @override
  String get videoSortedBySize => '已按容量从大到小排序。';

  @override
  String videoSelectedSummary(int count, String size) {
    return '已选择 $count 个 · 可释放 $size';
  }

  @override
  String get videoLongPressPreview => '长按预览';

  @override
  String get videoEmptyTitle => '没有需要清理的视频';

  @override
  String get videoEmptyDescription => '当前没有可访问的视频。';

  @override
  String get videoPermissionDescription => '如需查看并清理大视频，\n请允许访问照片图库。';

  @override
  String get videoPreparing => '正在准备视频。';

  @override
  String get videoPlaybackFailed => '无法播放视频。';

  @override
  String get videoPlayerUnavailable => '无法准备视频播放器。';

  @override
  String get videoSizeUnavailable => '无法确定视频画面尺寸。';

  @override
  String get select => '选择';

  @override
  String get travelPickStartTime => '选择开始时间';

  @override
  String get travelPickEndTime => '选择结束时间';

  @override
  String get travelPickDate => '选择日期';

  @override
  String get travelEnterAlbumName => '请输入相册名称。';

  @override
  String get travelSelectStartAndEndDate => '请选择开始日期和结束日期。';

  @override
  String get travelEndMustBeAfterStart => '结束日期和时间必须晚于开始时间。';

  @override
  String get travelNoAssetsInRange => '所选日期和时间范围内没有照片或视频。';

  @override
  String travelAlbumCreated(int count) {
    return '已使用 $count 个项目创建相册。';
  }

  @override
  String travelAlbumCreateError(String error) {
    return '创建相册时出现问题：$error';
  }

  @override
  String get travelSelectDate => '选择日期';

  @override
  String get travelAlbumTitle => '日期与时间相册';

  @override
  String get travelAlbumHeroTitle => '一次收集指定日期和时间范围内的\n照片与视频。';

  @override
  String get travelAlbumNameLabel => '相册名称';

  @override
  String get travelAlbumNameHint => '例如：济州岛旅行、运动会、演唱会';

  @override
  String get travelStartSectionTitle => '开始';

  @override
  String get travelStartDate => '开始日期';

  @override
  String get travelStartTime => '开始时间';

  @override
  String get travelEndSectionTitle => '结束';

  @override
  String get travelEndDate => '结束日期';

  @override
  String get travelEndTime => '结束时间';

  @override
  String get travelCreatingAlbum => '正在创建相册...';

  @override
  String get travelCreateAlbum => '创建相册';

  @override
  String get travelInfoDescription => '系统会根据“照片”中保存的拍摄日期和时间查找项目。';

  @override
  String get permissionTitle => '让照片更整洁，\n轻松完成整理';

  @override
  String get permissionDescription => '查找重复和不需要的照片，\n轻松释放 iPhone 存储空间。';

  @override
  String get permissionPrivacyTitle => '照片会被安全处理';

  @override
  String get permissionPrivacyDescription => '所有照片分析都在设备本地完成，\n不会上传到外部服务器。';

  @override
  String get permissionStartButton => '开始整理照片';

  @override
  String get permissionBottomDescription => '您可以随时在 iPhone 设置中更改照片访问权限。';

  @override
  String get permissionDialogTitle => '需要照片访问权限';

  @override
  String get permissionDialogDescription =>
      '为了查找重复照片并整理存储空间，Pomu 需要访问您的照片图库。\n\n照片只会在设备本地处理，不会上传到外部服务器。';

  @override
  String get scanCheckingNewPhotos => '正在检查新照片';

  @override
  String get scanAnalyzingPhotos => 'AI 正在分析照片';

  @override
  String get scanPreparingAlbums => '正在准备相册';

  @override
  String get scanCompleteTitle => '整理完成';

  @override
  String get scanWorkingTitle => '正在整理照片';

  @override
  String get scanBackHome => '返回首页';

  @override
  String get scanStepPhotoCheck => '检查照片';

  @override
  String get scanStepAiAnalysis => 'AI 分析';

  @override
  String get scanStepAlbumCreation => '创建相册';

  @override
  String scanTotalOrganized(int count) {
    return '已整理 $count 张照片';
  }

  @override
  String scanAlbumCount(int count) {
    return '已分类到 $count 个相册';
  }

  @override
  String photoCount(int count) {
    return '$count 张';
  }

  @override
  String get categoryPets => '宠物';

  @override
  String get categoryPeople => '人物';

  @override
  String get categoryFood => '食物';

  @override
  String get categoryLandscape => '风景';

  @override
  String get categoryDocuments => '文档';

  @override
  String get categoryScreenshots => '截图';

  @override
  String get categoryReceipts => '收据';

  @override
  String get categoryOther => '其他';

  @override
  String get albumNameSettingsTitle => '相册名称设置';

  @override
  String get reset => '重置';

  @override
  String get save => '保存';

  @override
  String get albumNamesSaved => '相册名称已保存。';

  @override
  String get albumNamesReset => '已恢复默认相册名称。';

  @override
  String get defaultNameLabel => '默认名称';

  @override
  String get customNameLabel => '自定义名称';

  @override
  String get albumNameEmptyHint => '留空则使用默认名称';

  @override
  String get albumNameDefaultHelp => '不输入时，将使用默认名称创建相册。';

  @override
  String defaultAlbumName(String category) {
    return 'Pomu $category';
  }

  @override
  String get saving => '正在保存...';

  @override
  String get purchaseErrorStatusUnavailable => '无法检查购买状态。';

  @override
  String get purchaseErrorStoreUnavailable => '当前无法使用 App Store 购买。';

  @override
  String get purchaseErrorProductLoadFailed => '无法加载商品信息，请稍后重试。';

  @override
  String get purchaseErrorProductNotFound => '在 App Store 中找不到该购买商品。';

  @override
  String get purchaseErrorNoRegisteredProducts => '当前没有已注册的购买商品。';

  @override
  String get purchaseErrorProductUnavailable => '商品信息尚未准备好。';

  @override
  String get purchaseErrorStartFailed => '无法开始购买。';

  @override
  String get purchaseErrorVerificationFailed => '无法验证购买。';

  @override
  String get purchaseErrorFailed => '无法完成购买。';

  @override
  String get purchaseErrorRestoreFailed => '无法恢复购买。';

  @override
  String get purchaseErrorCompletionFailed => '完成购买时出现问题。';

  @override
  String get duplicateSortSheetTitle => '请选择结果排序方式';

  @override
  String get duplicateSortSheetDescription => '重复照片组将按照您选择的顺序显示。';

  @override
  String get duplicateSortMostTitle => '重复照片最多优先';

  @override
  String get duplicateSortMostDescription => '优先显示照片数量较多的组';

  @override
  String get duplicateSortNewestTitle => '最新照片优先';

  @override
  String get duplicateSortNewestDescription => '优先显示包含最近拍摄照片的组';

  @override
  String get duplicateSortOldestTitle => '最旧照片优先';

  @override
  String get duplicateSortOldestDescription => '优先显示包含较早拍摄照片的组';

  @override
  String get duplicateSortStartButton => '按此顺序开始扫描';

  @override
  String get duplicateDeleteEntireTooltip => '删除整个分组';

  @override
  String get duplicateDeleteEntireTitle => '要删除此分组中的所有照片吗？';

  @override
  String duplicateDeleteEntireDescription(int photoCount) {
    return '此分组中的全部 $photoCount 张照片将移至 Apple 照片的“最近删除”中。';
  }

  @override
  String get duplicateDeleteEntireWarning =>
      '标记为“保留”的照片也会一起删除。\n此操作无法在 Pomu 中撤销。';

  @override
  String duplicateDeleteEntireButton(int photoCount) {
    return '删除全部 $photoCount 张';
  }

  @override
  String scanProcessedCount(int completed, int total) {
    return '$completed / $total';
  }

  @override
  String scanProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String scanRemainingPhotos(int count) {
    return '剩余$count张';
  }

  @override
  String get scanCalculatingRemainingTime => '正在计算剩余时间';

  @override
  String get scanAlmostDone => '即将完成';

  @override
  String get scanLessThanOneMinuteRemaining => '剩余不到1分钟';

  @override
  String scanEstimatedMinutesRemaining(int minutes) {
    return '预计还需$minutes分钟';
  }

  @override
  String scanEstimatedHoursRemaining(int hours) {
    return '预计还需$hours小时';
  }

  @override
  String scanEstimatedHoursMinutesRemaining(int hours, int minutes) {
    return '预计还需$hours小时$minutes分钟';
  }

  @override
  String get scanOrganizeFailedTitle => '无法整理照片';

  @override
  String get scanOrganizeFailedDescription => '整理照片时出现问题，请稍后重试。';

  @override
  String get scanRetry => '重试';
}
