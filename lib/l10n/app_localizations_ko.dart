// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Pomu';

  @override
  String get duplicateCleanupTitle => '중복 사진 정리';

  @override
  String get later => '나중에';

  @override
  String get restorePurchase => '구매 복원';

  @override
  String get oneTimePurchase => '구독이 아닌 일회성 구매예요.';

  @override
  String get paymentThroughApple => '결제는 Apple ID를 통해 진행됩니다.';

  @override
  String get duplicateIntroTitle => '비슷하게 보이는 사진을\n먼저 후보로 찾아볼게요.';

  @override
  String get duplicateIntroDescription => '지금은 삭제하지 않고, 보관할 사진과 삭제 후보만 보여줘요.';

  @override
  String get duplicateSavingShort => '결과 저장 중...';

  @override
  String get duplicateAnalyzingShort => '분석 중...';

  @override
  String get duplicateScanAgain => '다시 검사하기';

  @override
  String get duplicateFindCandidates => '중복 후보 찾기';

  @override
  String get loading => '불러오는 중...';

  @override
  String get duplicateLoadMore => '중복 후보 더 보기';

  @override
  String get duplicateRestoringLastResult => '마지막 검사 결과를 불러오고 있어요.';

  @override
  String get duplicateSavingResult => '검사 결과 저장 중...';

  @override
  String get duplicateReanalyzing => '중복 사진 다시 분석 중...';

  @override
  String get duplicateSavingSafely => '검사 결과를 안전하게 저장하고 있어요.';

  @override
  String get duplicateFindingCandidates => '중복 후보를 찾고 있어요.';

  @override
  String get duplicateContinueSoon => '잠시 후 바로 정리를 계속할 수 있어요.';

  @override
  String get duplicateMayTakeTime => '사진이 많을수록 조금 시간이 걸릴 수 있어요.';

  @override
  String get duplicateKeeperMinimum => '보관할 사진은 최소 1장 필요해요.';

  @override
  String get purchaseCompletedContinueDelete => '구매가 완료됐어요. 삭제를 계속 진행할게요.';

  @override
  String get deleteCanceledOrFailed => '삭제가 취소되었거나 실패했어요.';

  @override
  String get deletePreparation => '삭제 준비';

  @override
  String get deletedPhotosMoveToRecentlyDeleted => '삭제한 사진은 최근 삭제된 항목으로 이동해요.';

  @override
  String get cancel => '취소';

  @override
  String get unableToCheckSize => '용량을 확인하지 못했어요';

  @override
  String get noPhotosToDelete => '삭제할 사진 없음';

  @override
  String get keep => '✓ 보관';

  @override
  String get deleteCandidate => '삭제 후보';

  @override
  String get noRemainingDuplicateCandidates => '현재 남아 있는 중복 후보가 없어요';

  @override
  String get noAnalysisResult => '아직 분석 결과가 없어요';

  @override
  String get scanAgainIfNewPhotos => '새로운 사진이 추가되었다면\n다시 검사해주세요.';

  @override
  String get tapFindCandidatesGuide => '중복 후보 찾기를 눌러\n사진 보관함을 검사해주세요.';

  @override
  String get duplicateSavingWait => '검사 결과를 저장하고 있어요. 잠시만 기다려주세요.';

  @override
  String get duplicateAnalyzingWait => '중복 사진을 분석하고 있어요. 잠시만 기다려주세요.';

  @override
  String duplicateLoadLastResultError(String error) {
    return '마지막 검사 결과를 불러오지 못했어요: $error';
  }

  @override
  String duplicateLoadMoreError(String error) {
    return '중복 후보를 더 불러오지 못했어요: $error';
  }

  @override
  String duplicateAnalysisError(String error) {
    return '중복 사진 분석 중 문제가 발생했어요: $error';
  }

  @override
  String duplicateSaveDeleteResultError(String error) {
    return '삭제 결과를 저장하는 중 문제가 발생했어요: $error';
  }

  @override
  String duplicateProgress(int percent, int current, int total) {
    return '$percent% · $current / $total 그룹 분석 중';
  }

  @override
  String duplicateSummaryPartial(int total, int visible, int deleteCount) {
    return '전체 중복 후보 $total개 그룹\n현재 $visible개 표시 중 · 삭제 후보 $deleteCount장';
  }

  @override
  String duplicateSummaryFull(int total, int deleteCount) {
    return '중복 후보 $total개 그룹\n삭제 후보 $deleteCount장';
  }

  @override
  String freeDeleteCompleted(int count) {
    return '$count장의 사진을 삭제했어요. 첫 무료 정리를 사용했어요.';
  }

  @override
  String deleteMovedToRecentlyDeleted(int count) {
    return '$count장의 사진을 최근 삭제된 항목으로 이동했어요.';
  }

  @override
  String deleteCandidatesReview(int count) {
    return '삭제 후보 $count장을 다시 확인해주세요.';
  }

  @override
  String estimatedSpace(String size) {
    return '예상 확보 공간 $size';
  }

  @override
  String deleteCount(int count) {
    return '$count장 삭제';
  }

  @override
  String duplicateCandidateCount(int count) {
    return '중복 후보 $count장';
  }

  @override
  String keeperAndDeleteCount(int keepCount, int deleteCount) {
    return '보관 $keepCount장 · 삭제 후보 $deleteCount장';
  }

  @override
  String deletePreparationCount(int count) {
    return '삭제 준비 ($count장)';
  }

  @override
  String get homeHeroTitle => '아이폰 사진을 정리하고\n저장공간을 되찾아보세요';

  @override
  String get homeHeroSubtitle => '중복 사진과 불필요한 파일을 찾아\n안전하게 정리할 수 있어요.';

  @override
  String get homeCleanupSectionTitle => '정리하기';

  @override
  String get homeCleanupSectionSubtitle => '저장공간을 차지하는 사진과 영상을 확인해요.';

  @override
  String get homeScreenshotCleanupTitle => '스크린샷 정리';

  @override
  String get homeScreenshotCleanupDescription => '오래된 스크린샷을 한곳에서 확인하고 정리해요.';

  @override
  String get homeLargeVideoCleanupTitle => '큰 동영상 정리';

  @override
  String get homeLargeVideoCleanupDescription =>
      '저장공간을 많이 차지하는 동영상을 용량순으로 확인해요.';

  @override
  String get homeAlbumSectionTitle => '앨범 만들기';

  @override
  String get homeAlbumSectionSubtitle => '사진을 원하는 기준으로 묶어 앨범을 만들어요.';

  @override
  String get homeDateTimeAlbumTitle => '기간·시간별 앨범 만들기';

  @override
  String get homeDateTimeAlbumDescription => '원하는 날짜와 시간대를 골라 앨범을 만들어요.';

  @override
  String get homeAutoClassificationTitle => '사진 자동 분류';

  @override
  String get homeAutoClassificationDescription => '사진을 분석해 주제별 앨범으로 정리해요.';

  @override
  String get available => '사용 가능';

  @override
  String get beta => 'Beta';

  @override
  String get settings => '설정';

  @override
  String get analysisComplete => '분석 완료';

  @override
  String get availableNow => '지금 사용 가능';

  @override
  String get homeDuplicateLoading => '중복 사진 정보를 불러오고 있어요.';

  @override
  String get homeDuplicateBeforeScanDescription =>
      '사진 보관함에서 중복 사진을 찾아\n확보할 수 있는 공간을 확인해보세요.';

  @override
  String get homeDuplicateCleanDescription =>
      '현재 정리할 중복 사진이 없어요.\n사진 보관함이 깔끔해요.';

  @override
  String get homeDuplicateHasCandidatesDescription => '비슷한 사진을 찾아 정리해요.';

  @override
  String get homeFindDuplicates => '중복 사진 찾아보기';

  @override
  String get homeCleanDuplicates => '중복 사진 정리하기';

  @override
  String get homeStartFirstScan => '첫 검사를 시작해보세요';

  @override
  String get homeFirstScanDescription => '사진을 삭제하지 않고\n중복 후보만 먼저 찾아드려요.';

  @override
  String get homeNoDuplicatesTitle => '정리할 중복 사진이 없어요';

  @override
  String get homeNoDuplicatesDescription => '지금 사진 보관함은 깔끔한 상태예요.';

  @override
  String homeGroupCount(int count) {
    return '$count개 그룹';
  }

  @override
  String homeDeleteCandidateCount(int count) {
    return '삭제 후보 $count장';
  }

  @override
  String get homeReclaimableBeforeDelete => '확보 용량은 삭제 전에 확인할 수 있어요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsPhotoCleanupSectionTitle => '사진 정리';

  @override
  String get settingsPhotoCleanupSectionSubtitle => '저장된 검사 결과를 관리해요.';

  @override
  String get settingsResetDuplicateTitle => '중복 사진 검사 결과 초기화';

  @override
  String get settingsResetDuplicateSubtitle => '저장된 결과와 처리 완료 기록을 지우고 다시 검사해요.';

  @override
  String get settingsAlbumSectionTitle => '앨범';

  @override
  String get settingsAlbumSectionSubtitle => '자동 생성되는 앨범 이름을 설정해요.';

  @override
  String get settingsAutoAlbumNameTitle => '자동 분류 앨범 이름';

  @override
  String get settingsAutoAlbumNameSubtitle => '사진 자동 분류에 사용할 앨범 이름을 변경해요.';

  @override
  String get settingsAppSectionTitle => '앱 설정';

  @override
  String get settingsAppSectionSubtitle => 'Pomu의 기본 설정을 확인해요.';

  @override
  String get settingsLanguageTitle => '언어';

  @override
  String get settingsLanguageSubtitle => '현재 아이폰의 앱 언어 설정을 사용해요.';

  @override
  String get settingsInfoSectionTitle => '앱 정보';

  @override
  String get settingsInfoSectionSubtitle => 'Pomu에 대한 정보를 확인해요.';

  @override
  String get settingsPrivacyPolicyTitle => '개인정보 처리방침';

  @override
  String get settingsPrivacyPolicySubtitle => '개인정보 처리 내용을 확인해요.';

  @override
  String get settingsTermsTitle => '이용약관';

  @override
  String get settingsTermsSubtitle => '서비스 이용약관을 확인해요.';

  @override
  String get settingsContactTitle => '문의하기';

  @override
  String get settingsContactSubtitle => '앱 이용 중 궁금한 점을 문의해요.';

  @override
  String get settingsAppVersionTitle => '앱 버전';

  @override
  String get comingSoon => '준비 중';

  @override
  String get settingsResetDialogTitle => '검사 결과를 초기화할까요?';

  @override
  String get settingsResetDialogDescription =>
      '저장된 중복 그룹과 처리 완료 기록을\n초기화하고 처음부터 다시 검사해요.';

  @override
  String get settingsResetNoticeResolvedGroups => '이전에 처리한 그룹도 다시 나타날 수 있어요.';

  @override
  String get settingsResetNoticePhotosSafe => '아이폰 사진은 삭제되거나 변경되지 않아요.';

  @override
  String get settingsResetNoticePurchaseKept => '구매 기록과 무료 이용 기록은 유지돼요.';

  @override
  String get settingsResetAction => '검사 결과 초기화';

  @override
  String get settingsResetSuccess => '중복 사진 검사 결과를 초기화했어요.';

  @override
  String get settingsResetFailure => '초기화하지 못했어요. 잠시 후 다시 시도해주세요.';

  @override
  String get purchaseLifetimeBadge => '한 번 구매로 영구 이용';

  @override
  String get purchaseTitle => '중복 사진 정리를\n계속 이용해보세요';

  @override
  String get purchaseDescription =>
      '첫 번째 중복 그룹은 무료로 정리했어요.\n이제 제한 없이 계속 정리할 수 있어요.';

  @override
  String get purchaseLoadingProduct => '상품 정보 확인 중';

  @override
  String get purchaseOneTimeNoExtraCharge => '일회성 결제 · 추가 결제 없음';

  @override
  String get purchaseBenefitLifetimeTitle => '영구 이용';

  @override
  String get purchaseBenefitLifetimeDescription => '한 번만 결제';

  @override
  String get purchaseBenefitUnlimitedTitle => '무제한 정리';

  @override
  String get purchaseBenefitUnlimitedDescription => '그룹 개수 제한 없음';

  @override
  String get purchaseBenefitRestoreTitle => '구매 복원';

  @override
  String get purchaseBenefitRestoreDescription => '재설치 후에도 복원';

  @override
  String get purchaseBenefitNoSubscriptionTitle => '구독 없음';

  @override
  String get purchaseBenefitNoSubscriptionDescription => '매달 결제하지 않아요';

  @override
  String get purchaseLoadFailed => '상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.';

  @override
  String get purchaseReloadProduct => '상품 정보 다시 불러오기';

  @override
  String get purchaseRestoring => '구매 내역을 확인하고 있어요.';

  @override
  String get purchaseRestoringShort => '구매 내역 확인 중...';

  @override
  String purchaseWithPrice(String price) {
    return '$price으로 영구 이용';
  }

  @override
  String get screenshotLoadFailed => '스크린샷을 불러오지 못했어요.';

  @override
  String get screenshotDeleteFailed => '스크린샷을 삭제하지 못했어요.';

  @override
  String screenshotDeletedSuccess(int count) {
    return '$count장의 스크린샷을 최근 삭제된 항목으로 이동했어요.';
  }

  @override
  String get screenshotDeletePreparationTitle => '스크린샷 삭제 준비';

  @override
  String screenshotDeleteReview(int count) {
    return '선택한 스크린샷 $count장을 확인해주세요.';
  }

  @override
  String get screenshotMoveToRecentlyDeleted =>
      '삭제한 항목은 사진 앱의 최근 삭제된 항목으로 이동해요.';

  @override
  String get screenshotDeselectAll => '선택 해제';

  @override
  String get screenshotSelectAll => '전체 선택';

  @override
  String get deleting => '삭제 중...';

  @override
  String get screenshotSelectToDelete => '삭제할 스크린샷을 선택해주세요';

  @override
  String screenshotDeleteSelected(int count) {
    return '선택한 $count장 삭제';
  }

  @override
  String screenshotTotalCount(int count) {
    return '스크린샷 $count장';
  }

  @override
  String get screenshotSelectToDeleteWithPeriod => '삭제할 스크린샷을 선택해주세요.';

  @override
  String screenshotSelectedCount(int count) {
    return '$count장을 선택했어요.';
  }

  @override
  String get photoPermissionRequiredTitle => '사진 접근 권한이 필요해요';

  @override
  String get screenshotPermissionDescription =>
      '스크린샷을 확인하고 정리하려면\n사진 보관함 접근을 허용해주세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get screenshotLimitedAccessDescription =>
      '선택한 사진만 접근 중이에요. 모든 스크린샷을 보려면 접근 사진을 추가해주세요.';

  @override
  String get addPhotos => '추가';

  @override
  String get screenshotEmptyTitle => '정리할 스크린샷이 없어요';

  @override
  String get screenshotEmptyDescription =>
      '현재 사진 보관함에 스크린샷이 없거나\n접근 가능한 스크린샷이 없어요.';

  @override
  String get videoLoadFailed => '동영상을 불러오지 못했어요.';

  @override
  String videoDeletedSuccess(int count) {
    return '$count개의 동영상을 최근 삭제된 항목으로 이동했어요.';
  }

  @override
  String get videoDeleteFailed => '동영상을 삭제하지 못했어요.';

  @override
  String get videoLoadingOriginal => '동영상을 불러오고 있어요.';

  @override
  String get videoOriginalLoadFailed => '동영상 원본 파일을 불러오지 못했어요.';

  @override
  String get videoDeletePreparationTitle => '동영상 삭제 준비';

  @override
  String videoDeleteReview(int count) {
    return '선택한 동영상 $count개를 확인해주세요.';
  }

  @override
  String get videoMoveToRecentlyDeleted => '삭제한 동영상은 사진 앱의 최근 삭제된 항목으로 이동해요.';

  @override
  String videoDeleteCount(int count) {
    return '$count개 삭제';
  }

  @override
  String get videoSelectToDelete => '삭제할 동영상을 선택해주세요';

  @override
  String videoDeleteSelectedWithSize(int count, String size) {
    return '$count개 삭제 · $size';
  }

  @override
  String get videoFindingLargeVideos => '큰 동영상을 찾고 있어요';

  @override
  String videoCheckingSizes(int current, int total) {
    return '$current / $total개 용량 확인 중';
  }

  @override
  String get videoLoadingList => '동영상 목록을 불러오고 있어요.';

  @override
  String get videoMayTakeTime => '동영상이 많거나 iCloud에 있으면 시간이 걸릴 수 있어요.';

  @override
  String videoSummary(int count, String size) {
    return '동영상 $count개 · $size';
  }

  @override
  String get videoSortedBySize => '용량이 큰 순서로 표시했어요.';

  @override
  String videoSelectedSummary(int count, String size) {
    return '$count개 선택 · $size 확보 가능';
  }

  @override
  String get videoLongPressPreview => '길게 눌러 크게 보기';

  @override
  String get videoEmptyTitle => '정리할 동영상이 없어요';

  @override
  String get videoEmptyDescription => '현재 접근 가능한 동영상이 없어요.';

  @override
  String get videoPermissionDescription =>
      '큰 동영상을 확인하고 정리하려면\n사진 보관함 접근을 허용해주세요.';

  @override
  String get videoPreparing => '동영상을 준비하고 있어요.';

  @override
  String get videoPlaybackFailed => '동영상을 재생하지 못했어요.';

  @override
  String get videoPlayerUnavailable => '동영상 플레이어를 준비하지 못했어요.';

  @override
  String get videoSizeUnavailable => '동영상 화면 크기를 확인하지 못했어요.';

  @override
  String get select => '선택';

  @override
  String get travelPickStartTime => '시작 시간 선택';

  @override
  String get travelPickEndTime => '종료 시간 선택';

  @override
  String get travelPickDate => '날짜 선택';

  @override
  String get travelEnterAlbumName => '앨범 이름을 입력해주세요.';

  @override
  String get travelSelectStartAndEndDate => '시작 날짜와 종료 날짜를 선택해주세요.';

  @override
  String get travelEndMustBeAfterStart => '종료 날짜와 시간은 시작 시점보다 늦어야 해요.';

  @override
  String get travelNoAssetsInRange => '선택한 날짜와 시간대에 사진이나 영상이 없어요.';

  @override
  String travelAlbumCreated(int count) {
    return '$count개의 항목으로 앨범을 만들었어요.';
  }

  @override
  String travelAlbumCreateError(String error) {
    return '앨범 생성 중 문제가 발생했어요: $error';
  }

  @override
  String get travelSelectDate => '날짜 선택';

  @override
  String get travelAlbumTitle => '기간·시간 앨범';

  @override
  String get travelAlbumHeroTitle => '원하는 날짜와 시간대의\n사진과 영상을 한 번에 모아요.';

  @override
  String get travelAlbumNameLabel => '앨범 이름';

  @override
  String get travelAlbumNameHint => '예: 제주도 여행, 운동회, 콘서트';

  @override
  String get travelStartSectionTitle => '시작 시점';

  @override
  String get travelStartDate => '시작 날짜';

  @override
  String get travelStartTime => '시작 시간';

  @override
  String get travelEndSectionTitle => '종료 시점';

  @override
  String get travelEndDate => '종료 날짜';

  @override
  String get travelEndTime => '종료 시간';

  @override
  String get travelCreatingAlbum => '앨범 생성 중...';

  @override
  String get travelCreateAlbum => '앨범 만들기';

  @override
  String get travelInfoDescription => '사진 앱에 저장된 촬영 날짜와 시간을 기준으로 항목을 찾아요.';

  @override
  String get permissionTitle => '사진을 더 깔끔하게\n정리해드릴게요';

  @override
  String get permissionDescription =>
      '중복 사진과 불필요한 사진을 찾아\n아이폰 저장공간을 쉽게 확보할 수 있어요.';

  @override
  String get permissionPrivacyTitle => '사진은 안전하게 처리돼요';

  @override
  String get permissionPrivacyDescription =>
      '사진은 기기 안에서만 분석되며\n외부 서버로 업로드되지 않아요.';

  @override
  String get permissionStartButton => '사진 정리 시작하기';

  @override
  String get permissionBottomDescription => '권한은 언제든 아이폰 설정에서 변경할 수 있어요.';

  @override
  String get permissionDialogTitle => '사진 접근 권한이 필요해요';

  @override
  String get permissionDialogDescription =>
      '중복 사진을 찾고 저장공간을 정리하려면 사진 보관함 접근 권한이 필요해요.\n\n사진은 기기 안에서만 처리되며 외부 서버로 업로드되지 않아요.';

  @override
  String get scanCheckingNewPhotos => '새 사진을 확인하고 있어요';

  @override
  String get scanAnalyzingPhotos => 'AI가 사진을 분석하고 있어요';

  @override
  String get scanPreparingAlbums => '앨범을 준비하고 있어요';

  @override
  String get scanCompleteTitle => '정리가 완료됐어요';

  @override
  String get scanWorkingTitle => '사진을 정리하고 있어요';

  @override
  String get scanBackHome => '홈으로 돌아가기';

  @override
  String get scanStepPhotoCheck => '사진 확인';

  @override
  String get scanStepAiAnalysis => 'AI 분석';

  @override
  String get scanStepAlbumCreation => '앨범 생성';

  @override
  String scanTotalOrganized(int count) {
    return '$count장 정리 완료';
  }

  @override
  String scanAlbumCount(int count) {
    return '$count개 앨범으로 분류했어요';
  }

  @override
  String photoCount(int count) {
    return '$count장';
  }

  @override
  String get categoryPets => '반려동물';

  @override
  String get categoryPeople => '사람';

  @override
  String get categoryFood => '음식';

  @override
  String get categoryLandscape => '풍경';

  @override
  String get categoryDocuments => '문서';

  @override
  String get categoryScreenshots => '스크린샷';

  @override
  String get categoryReceipts => '영수증';

  @override
  String get categoryOther => '기타';

  @override
  String get albumNameSettingsTitle => '앨범 이름 설정';

  @override
  String get reset => '초기화';

  @override
  String get save => '저장';

  @override
  String get albumNamesSaved => '앨범 이름이 저장되었어요.';

  @override
  String get albumNamesReset => '기본 앨범 이름으로 되돌렸어요.';

  @override
  String get defaultNameLabel => '기본 이름';

  @override
  String get customNameLabel => '사용자 지정 이름';

  @override
  String get albumNameEmptyHint => '비워두면 기본 이름 사용';

  @override
  String get albumNameDefaultHelp => '입력하지 않으면 기본 이름으로 앨범이 생성돼요.';

  @override
  String defaultAlbumName(String category) {
    return 'Pomu $category';
  }

  @override
  String get saving => '저장 중...';

  @override
  String get purchaseErrorStatusUnavailable => '결제 상태를 확인하지 못했어요.';

  @override
  String get purchaseErrorStoreUnavailable => '현재 App Store 결제를 사용할 수 없어요.';

  @override
  String get purchaseErrorProductLoadFailed =>
      '상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.';

  @override
  String get purchaseErrorProductNotFound => 'App Store에서 결제 상품을 찾지 못했어요.';

  @override
  String get purchaseErrorNoRegisteredProducts => '등록된 결제 상품이 없어요.';

  @override
  String get purchaseErrorProductUnavailable => '구매할 상품 정보를 아직 불러오지 못했어요.';

  @override
  String get purchaseErrorStartFailed => '결제를 시작하지 못했어요.';

  @override
  String get purchaseErrorVerificationFailed => '구매 확인에 실패했어요.';

  @override
  String get purchaseErrorFailed => '결제를 완료하지 못했어요.';

  @override
  String get purchaseErrorRestoreFailed => '구매 내역을 복원하지 못했어요.';

  @override
  String get purchaseErrorCompletionFailed => '구매 완료 처리 중 문제가 발생했어요.';

  @override
  String get duplicateSortSheetTitle => '결과 순서를 선택해주세요';

  @override
  String get duplicateSortSheetDescription => '선택한 순서대로 중복 그룹을 정리해 보여드려요.';

  @override
  String get duplicateSortMostTitle => '중복 사진이 많은 순';

  @override
  String get duplicateSortMostDescription => '사진 수가 많은 그룹부터 표시';

  @override
  String get duplicateSortNewestTitle => '최신 사진부터';

  @override
  String get duplicateSortNewestDescription => '최근에 촬영한 사진이 포함된 그룹부터 표시';

  @override
  String get duplicateSortOldestTitle => '오래된 사진부터';

  @override
  String get duplicateSortOldestDescription => '오래전에 촬영한 사진이 포함된 그룹부터 표시';

  @override
  String get duplicateSortStartButton => '이 순서로 검사 시작';

  @override
  String get duplicateDeleteEntireTooltip => '이 그룹 전체 삭제';

  @override
  String get duplicateDeleteEntireTitle => '이 그룹의 사진을 모두 삭제할까요?';

  @override
  String duplicateDeleteEntireDescription(int photoCount) {
    return '이 그룹의 사진 $photoCount장이 모두 Apple 사진의 ‘최근 삭제된 항목’으로 이동합니다.';
  }

  @override
  String get duplicateDeleteEntireWarning =>
      '보관으로 선택한 사진도 함께 삭제됩니다.\n포무에서는 이 작업을 되돌릴 수 없습니다.';

  @override
  String duplicateDeleteEntireButton(int photoCount) {
    return '$photoCount장 모두 삭제';
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
    return '$count장 남음';
  }

  @override
  String get scanCalculatingRemainingTime => '남은 시간 계산 중';

  @override
  String get scanAlmostDone => '거의 완료';

  @override
  String get scanLessThanOneMinuteRemaining => '1분 미만 남음';

  @override
  String scanEstimatedMinutesRemaining(int minutes) {
    return '약 $minutes분 남음';
  }

  @override
  String scanEstimatedHoursRemaining(int hours) {
    return '약 $hours시간 남음';
  }

  @override
  String scanEstimatedHoursMinutesRemaining(int hours, int minutes) {
    return '약 $hours시간 $minutes분 남음';
  }

  @override
  String get scanOrganizeFailedTitle => '사진을 정리하지 못했어요';

  @override
  String get scanOrganizeFailedDescription =>
      '사진을 정리하는 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get scanRetry => '다시 시도';

  @override
  String get autoClassificationIntroAppBarTitle => '사진 자동 분류';

  @override
  String get autoClassificationIntroTitle => '사진을 주제별 앨범으로\n자동 정리해드릴게요';

  @override
  String get autoClassificationIntroDescription =>
      'Pomu가 사진을 기기 안에서 분석해 반려동물, 사람, 음식, 풍경 등 주제별 앨범으로 정리해요.';

  @override
  String get autoClassificationWarningTitle => '첫 분석은 시간이 오래 걸릴 수 있어요';

  @override
  String get autoClassificationWarningDescription =>
      '사진이 많을수록 분석 시간이 길어질 수 있어요. 분석 중에는 앱을 종료하지 않는 것이 좋아요.';

  @override
  String get autoClassificationPrivacyTitle => '사진은 기기 안에서만 분석돼요';

  @override
  String get autoClassificationPrivacyDescription =>
      '사진은 외부 서버로 전송되거나 업로드되지 않아요.';

  @override
  String get autoClassificationAlbumTitle => 'Apple 사진 앱에 앨범을 만들어요';

  @override
  String get autoClassificationAlbumDescription =>
      '분석이 끝나면 주제별 앨범이 Apple 사진 앱에 자동으로 생성돼요.';

  @override
  String get autoClassificationNextScanTitle => '다음부터는 새 사진만 확인해요';

  @override
  String get autoClassificationNextScanDescription =>
      '첫 분석이 끝난 뒤에는 새로 추가된 사진만 분석해 더 빠르게 정리해요.';

  @override
  String get autoClassificationStartButton => '사진 자동 분류 시작하기';

  @override
  String get autoClassificationStartNotice => '사진 수에 따라 분석에 시간이 걸릴 수 있어요.';
}
