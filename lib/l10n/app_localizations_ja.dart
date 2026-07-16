// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Pomu';

  @override
  String get duplicateCleanupTitle => '重複写真の整理';

  @override
  String get later => 'あとで';

  @override
  String get restorePurchase => '購入を復元';

  @override
  String get oneTimePurchase => 'サブスクリプションではなく、一度きりの購入です。';

  @override
  String get paymentThroughApple => 'お支払いはApple IDを通じて行われます。';

  @override
  String get duplicateIntroTitle => '似ている写真を\n先に候補として探します。';

  @override
  String get duplicateIntroDescription => 'まだ削除は行わず、残す写真と削除候補だけを表示します。';

  @override
  String get duplicateSavingShort => '結果を保存中...';

  @override
  String get duplicateAnalyzingShort => '解析中...';

  @override
  String get duplicateScanAgain => 'もう一度スキャン';

  @override
  String get duplicateFindCandidates => '重複候補を探す';

  @override
  String get loading => '読み込み中...';

  @override
  String get duplicateLoadMore => '重複候補をさらに表示';

  @override
  String get duplicateRestoringLastResult => '前回のスキャン結果を読み込んでいます。';

  @override
  String get duplicateSavingResult => 'スキャン結果を保存中...';

  @override
  String get duplicateReanalyzing => '重複写真を再解析中...';

  @override
  String get duplicateSavingSafely => 'スキャン結果を安全に保存しています。';

  @override
  String get duplicateFindingCandidates => '重複候補を探しています。';

  @override
  String get duplicateContinueSoon => 'まもなく整理を続けられます。';

  @override
  String get duplicateMayTakeTime => '写真が多い場合は少し時間がかかることがあります。';

  @override
  String get duplicateKeeperMinimum => '残す写真を1枚以上選んでください。';

  @override
  String get purchaseCompletedContinueDelete => '購入が完了しました。削除を続けます。';

  @override
  String get deleteCanceledOrFailed => '削除がキャンセルされたか失敗しました。';

  @override
  String get deletePreparation => '削除の確認';

  @override
  String get deletedPhotosMoveToRecentlyDeleted => '削除した写真は「最近削除した項目」に移動します。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get unableToCheckSize => '容量を確認できません';

  @override
  String get noPhotosToDelete => '削除する写真はありません';

  @override
  String get keep => '✓ 残す';

  @override
  String get deleteCandidate => '削除候補';

  @override
  String get noRemainingDuplicateCandidates => '重複候補は残っていません';

  @override
  String get noAnalysisResult => 'まだ解析結果がありません';

  @override
  String get scanAgainIfNewPhotos => '新しい写真を追加した場合は、もう一度スキャンしてください。';

  @override
  String get tapFindCandidatesGuide => '「重複候補を探す」をタップして写真ライブラリをスキャンしてください。';

  @override
  String get duplicateSavingWait => 'スキャン結果を保存しています。しばらくお待ちください。';

  @override
  String get duplicateAnalyzingWait => '重複写真を解析しています。しばらくお待ちください。';

  @override
  String duplicateLoadLastResultError(String error) {
    return '前回のスキャン結果を読み込めませんでした：$error';
  }

  @override
  String duplicateLoadMoreError(String error) {
    return '重複候補をさらに読み込めませんでした：$error';
  }

  @override
  String duplicateAnalysisError(String error) {
    return '重複写真の解析中に問題が発生しました：$error';
  }

  @override
  String duplicateSaveDeleteResultError(String error) {
    return '削除結果の保存中に問題が発生しました：$error';
  }

  @override
  String duplicateProgress(int percent, int current, int total) {
    return '$percent%・$current / $total グループを解析中';
  }

  @override
  String duplicateSummaryPartial(int total, int visible, int deleteCount) {
    return '重複候補は全$totalグループ\n現在$visible件を表示・削除候補$deleteCount枚';
  }

  @override
  String duplicateSummaryFull(int total, int deleteCount) {
    return '重複候補$totalグループ\n削除候補$deleteCount枚';
  }

  @override
  String freeDeleteCompleted(int count) {
    return '$count枚の写真を削除しました。無料整理を使用しました。';
  }

  @override
  String deleteMovedToRecentlyDeleted(int count) {
    return '$count枚の写真を「最近削除した項目」に移動しました。';
  }

  @override
  String deleteCandidatesReview(int count) {
    return '削除候補の写真$count枚をもう一度確認してください。';
  }

  @override
  String estimatedSpace(String size) {
    return '空き容量の目安：$size';
  }

  @override
  String deleteCount(int count) {
    return '$count枚を削除';
  }

  @override
  String duplicateCandidateCount(int count) {
    return '重複候補$count枚';
  }

  @override
  String keeperAndDeleteCount(int keepCount, int deleteCount) {
    return '残す$keepCount枚・削除候補$deleteCount枚';
  }

  @override
  String deletePreparationCount(int count) {
    return '削除の確認（$count枚）';
  }

  @override
  String get homeHeroTitle => 'iPhoneの写真を整理して\n空き容量を増やしましょう';

  @override
  String get homeHeroSubtitle => '重複写真や不要なファイルを見つけて\n安全に整理できます。';

  @override
  String get homeCleanupSectionTitle => '整理する';

  @override
  String get homeCleanupSectionSubtitle => 'ストレージを使用している写真や動画を確認します。';

  @override
  String get homeScreenshotCleanupTitle => 'スクリーンショット整理';

  @override
  String get homeScreenshotCleanupDescription => '古いスクリーンショットをまとめて確認・整理します。';

  @override
  String get homeLargeVideoCleanupTitle => '大きな動画を整理';

  @override
  String get homeLargeVideoCleanupDescription => '容量の大きい動画をサイズ順に確認します。';

  @override
  String get homeAlbumSectionTitle => 'アルバムを作成';

  @override
  String get homeAlbumSectionSubtitle => '写真を好きな条件でまとめてアルバムを作ります。';

  @override
  String get homeDateTimeAlbumTitle => '期間・時間別アルバム';

  @override
  String get homeDateTimeAlbumDescription => '日付と時間帯を選んでアルバムを作成します。';

  @override
  String get homeAutoClassificationTitle => '写真の自動分類';

  @override
  String get homeAutoClassificationDescription => '写真を解析し、テーマ別アルバムに整理します。';

  @override
  String get available => '利用可能';

  @override
  String get beta => 'ベータ';

  @override
  String get settings => '設定';

  @override
  String get analysisComplete => '解析完了';

  @override
  String get availableNow => '今すぐ利用可能';

  @override
  String get homeDuplicateLoading => '重複写真の情報を読み込んでいます。';

  @override
  String get homeDuplicateBeforeScanDescription =>
      '写真ライブラリから重複写真を見つけて\n空けられる容量を確認しましょう。';

  @override
  String get homeDuplicateCleanDescription => '整理する重複写真はありません。\n写真ライブラリはきれいです。';

  @override
  String get homeDuplicateHasCandidatesDescription => '似ている写真を見つけて整理します。';

  @override
  String get homeFindDuplicates => '重複写真を探す';

  @override
  String get homeCleanDuplicates => '重複写真を整理';

  @override
  String get homeStartFirstScan => '最初のスキャンを始めましょう';

  @override
  String get homeFirstScanDescription => '写真は削除せず、\nまず重複候補だけを探します。';

  @override
  String get homeNoDuplicatesTitle => '整理する重複写真はありません';

  @override
  String get homeNoDuplicatesDescription => '写真ライブラリはきれいな状態です。';

  @override
  String homeGroupCount(int count) {
    return '$countグループ';
  }

  @override
  String homeDeleteCandidateCount(int count) {
    return '削除候補$count枚';
  }

  @override
  String get homeReclaimableBeforeDelete => '空けられる容量は削除前に確認できます。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsPhotoCleanupSectionTitle => '写真整理';

  @override
  String get settingsPhotoCleanupSectionSubtitle => '保存されたスキャン結果を管理します。';

  @override
  String get settingsResetDuplicateTitle => '重複写真のスキャン結果をリセット';

  @override
  String get settingsResetDuplicateSubtitle => '保存済みの結果と処理履歴を消去して、もう一度スキャンします。';

  @override
  String get settingsAlbumSectionTitle => 'アルバム';

  @override
  String get settingsAlbumSectionSubtitle => '自動作成されるアルバム名を設定します。';

  @override
  String get settingsAutoAlbumNameTitle => '自動分類アルバム名';

  @override
  String get settingsAutoAlbumNameSubtitle => '写真の自動分類で使用するアルバム名を変更します。';

  @override
  String get settingsAppSectionTitle => 'アプリ設定';

  @override
  String get settingsAppSectionSubtitle => 'Pomuの基本設定を確認します。';

  @override
  String get settingsLanguageTitle => '言語';

  @override
  String get settingsLanguageSubtitle => 'iPhone設定でPomuに選択した言語を使用します。';

  @override
  String get settingsInfoSectionTitle => 'アプリ情報';

  @override
  String get settingsInfoSectionSubtitle => 'Pomuに関する情報を確認します。';

  @override
  String get settingsPrivacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get settingsPrivacyPolicySubtitle => '個人情報の取り扱いを確認します。';

  @override
  String get settingsTermsTitle => '利用規約';

  @override
  String get settingsTermsSubtitle => 'サービスの利用規約を確認します。';

  @override
  String get settingsContactTitle => 'お問い合わせ';

  @override
  String get settingsContactSubtitle => 'アプリの利用について問い合わせます。';

  @override
  String get settingsAppVersionTitle => 'アプリバージョン';

  @override
  String get comingSoon => '準備中';

  @override
  String get settingsResetDialogTitle => 'スキャン結果をリセットしますか？';

  @override
  String get settingsResetDialogDescription =>
      '保存された重複グループと処理履歴を消去し、\n最初からスキャンし直します。';

  @override
  String get settingsResetNoticeResolvedGroups => '以前に処理したグループも再表示される場合があります。';

  @override
  String get settingsResetNoticePhotosSafe => 'iPhoneの写真が削除・変更されることはありません。';

  @override
  String get settingsResetNoticePurchaseKept => '購入履歴と無料利用履歴は保持されます。';

  @override
  String get settingsResetAction => 'スキャン結果をリセット';

  @override
  String get settingsResetSuccess => '重複写真のスキャン結果をリセットしました。';

  @override
  String get settingsResetFailure => 'リセットできませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get purchaseLifetimeBadge => '一度の購入で永久利用';

  @override
  String get purchaseTitle => '重複写真の整理を\n引き続き利用しましょう';

  @override
  String get purchaseDescription => '最初の重複グループは無料で整理しました。\nこれからは制限なく利用できます。';

  @override
  String get purchaseLoadingProduct => '商品情報を確認中';

  @override
  String get purchaseOneTimeNoExtraCharge => '一度きりの支払い・追加料金なし';

  @override
  String get purchaseBenefitLifetimeTitle => '永久利用';

  @override
  String get purchaseBenefitLifetimeDescription => '支払いは一度だけ';

  @override
  String get purchaseBenefitUnlimitedTitle => '無制限整理';

  @override
  String get purchaseBenefitUnlimitedDescription => 'グループ数の制限なし';

  @override
  String get purchaseBenefitRestoreTitle => '購入を復元';

  @override
  String get purchaseBenefitRestoreDescription => '再インストール後も復元';

  @override
  String get purchaseBenefitNoSubscriptionTitle => 'サブスクなし';

  @override
  String get purchaseBenefitNoSubscriptionDescription => '毎月の支払いなし';

  @override
  String get purchaseLoadFailed => '商品情報を読み込めませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get purchaseReloadProduct => '商品情報を再読み込み';

  @override
  String get purchaseRestoring => '購入履歴を確認しています。';

  @override
  String get purchaseRestoringShort => '購入履歴を確認中...';

  @override
  String purchaseWithPrice(String price) {
    return '$priceで永久利用';
  }

  @override
  String get screenshotLoadFailed => 'スクリーンショットを読み込めませんでした。';

  @override
  String get screenshotDeleteFailed => 'スクリーンショットを削除できませんでした。';

  @override
  String screenshotDeletedSuccess(int count) {
    return '$count枚のスクリーンショットを「最近削除した項目」に移動しました。';
  }

  @override
  String get screenshotDeletePreparationTitle => 'スクリーンショット削除の確認';

  @override
  String screenshotDeleteReview(int count) {
    return '選択したスクリーンショット$count枚を確認してください。';
  }

  @override
  String get screenshotMoveToRecentlyDeleted =>
      '削除した項目は写真アプリの「最近削除した項目」に移動します。';

  @override
  String get screenshotDeselectAll => '選択解除';

  @override
  String get screenshotSelectAll => 'すべて選択';

  @override
  String get deleting => '削除中...';

  @override
  String get screenshotSelectToDelete => '削除するスクリーンショットを選択してください';

  @override
  String screenshotDeleteSelected(int count) {
    return '選択した$count枚を削除';
  }

  @override
  String screenshotTotalCount(int count) {
    return 'スクリーンショット$count枚';
  }

  @override
  String get screenshotSelectToDeleteWithPeriod => '削除するスクリーンショットを選択してください。';

  @override
  String screenshotSelectedCount(int count) {
    return '$count枚を選択しました。';
  }

  @override
  String get photoPermissionRequiredTitle => '写真へのアクセスが必要です';

  @override
  String get screenshotPermissionDescription =>
      'スクリーンショットを確認・整理するには\n写真ライブラリへのアクセスを許可してください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get screenshotLimitedAccessDescription =>
      '選択した写真のみにアクセスしています。すべてのスクリーンショットを表示するには、写真を追加してください。';

  @override
  String get addPhotos => '追加';

  @override
  String get screenshotEmptyTitle => '整理するスクリーンショットはありません';

  @override
  String get screenshotEmptyDescription =>
      '写真ライブラリにスクリーンショットがないか、\n現在アクセスできるスクリーンショットがありません。';

  @override
  String get videoLoadFailed => '動画を読み込めませんでした。';

  @override
  String videoDeletedSuccess(int count) {
    return '$count件の動画を「最近削除した項目」に移動しました。';
  }

  @override
  String get videoDeleteFailed => '動画を削除できませんでした。';

  @override
  String get videoLoadingOriginal => '動画を読み込んでいます。';

  @override
  String get videoOriginalLoadFailed => '動画の元ファイルを読み込めませんでした。';

  @override
  String get videoDeletePreparationTitle => '動画削除の確認';

  @override
  String videoDeleteReview(int count) {
    return '選択した動画$count件を確認してください。';
  }

  @override
  String get videoMoveToRecentlyDeleted => '削除した動画は写真アプリの「最近削除した項目」に移動します。';

  @override
  String videoDeleteCount(int count) {
    return '$count件を削除';
  }

  @override
  String get videoSelectToDelete => '削除する動画を選択してください';

  @override
  String videoDeleteSelectedWithSize(int count, String size) {
    return '$count件を削除・$size';
  }

  @override
  String get videoFindingLargeVideos => '大きな動画を探しています';

  @override
  String videoCheckingSizes(int current, int total) {
    return '$current / $total件の容量を確認中';
  }

  @override
  String get videoLoadingList => '動画一覧を読み込んでいます。';

  @override
  String get videoMayTakeTime => '動画が多い場合やiCloudに保存されている場合は時間がかかることがあります。';

  @override
  String videoSummary(int count, String size) {
    return '動画$count件・$size';
  }

  @override
  String get videoSortedBySize => '容量の大きい順に表示しています。';

  @override
  String videoSelectedSummary(int count, String size) {
    return '$count件選択・$size解放可能';
  }

  @override
  String get videoLongPressPreview => '長押ししてプレビュー';

  @override
  String get videoEmptyTitle => '整理する動画はありません';

  @override
  String get videoEmptyDescription => '現在アクセスできる動画はありません。';

  @override
  String get videoPermissionDescription =>
      '大きな動画を確認・整理するには\n写真ライブラリへのアクセスを許可してください。';

  @override
  String get videoPreparing => '動画を準備しています。';

  @override
  String get videoPlaybackFailed => '動画を再生できませんでした。';

  @override
  String get videoPlayerUnavailable => '動画プレーヤーを準備できませんでした。';

  @override
  String get videoSizeUnavailable => '動画の画面サイズを確認できませんでした。';

  @override
  String get select => '選択';

  @override
  String get travelPickStartTime => '開始時刻を選択';

  @override
  String get travelPickEndTime => '終了時刻を選択';

  @override
  String get travelPickDate => '日付を選択';

  @override
  String get travelEnterAlbumName => 'アルバム名を入力してください。';

  @override
  String get travelSelectStartAndEndDate => '開始日と終了日を選択してください。';

  @override
  String get travelEndMustBeAfterStart => '終了日時は開始日時より後に設定してください。';

  @override
  String get travelNoAssetsInRange => '選択した日時範囲に写真や動画がありません。';

  @override
  String travelAlbumCreated(int count) {
    return '$count件の項目でアルバムを作成しました。';
  }

  @override
  String travelAlbumCreateError(String error) {
    return 'アルバムの作成中に問題が発生しました：$error';
  }

  @override
  String get travelSelectDate => '日付を選択';

  @override
  String get travelAlbumTitle => '期間・時間アルバム';

  @override
  String get travelAlbumHeroTitle => '指定した日時範囲の\n写真と動画をまとめます。';

  @override
  String get travelAlbumNameLabel => 'アルバム名';

  @override
  String get travelAlbumNameHint => '例：済州島旅行、運動会、コンサート';

  @override
  String get travelStartSectionTitle => '開始';

  @override
  String get travelStartDate => '開始日';

  @override
  String get travelStartTime => '開始時刻';

  @override
  String get travelEndSectionTitle => '終了';

  @override
  String get travelEndDate => '終了日';

  @override
  String get travelEndTime => '終了時刻';

  @override
  String get travelCreatingAlbum => 'アルバムを作成中...';

  @override
  String get travelCreateAlbum => 'アルバムを作成';

  @override
  String get travelInfoDescription => '写真アプリに保存された撮影日時を基準に項目を探します。';
}
