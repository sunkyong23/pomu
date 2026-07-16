import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'Pomu'**
  String get appName;

  /// No description provided for @duplicateCleanupTitle.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 정리'**
  String get duplicateCleanupTitle;

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get later;

  /// No description provided for @restorePurchase.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get restorePurchase;

  /// No description provided for @oneTimePurchase.
  ///
  /// In ko, this message translates to:
  /// **'구독이 아닌 일회성 구매예요.'**
  String get oneTimePurchase;

  /// No description provided for @paymentThroughApple.
  ///
  /// In ko, this message translates to:
  /// **'결제는 Apple ID를 통해 진행됩니다.'**
  String get paymentThroughApple;

  /// No description provided for @duplicateIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'비슷하게 보이는 사진을\n먼저 후보로 찾아볼게요.'**
  String get duplicateIntroTitle;

  /// No description provided for @duplicateIntroDescription.
  ///
  /// In ko, this message translates to:
  /// **'지금은 삭제하지 않고, 보관할 사진과 삭제 후보만 보여줘요.'**
  String get duplicateIntroDescription;

  /// No description provided for @duplicateSavingShort.
  ///
  /// In ko, this message translates to:
  /// **'결과 저장 중...'**
  String get duplicateSavingShort;

  /// No description provided for @duplicateAnalyzingShort.
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get duplicateAnalyzingShort;

  /// No description provided for @duplicateScanAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 검사하기'**
  String get duplicateScanAgain;

  /// No description provided for @duplicateFindCandidates.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보 찾기'**
  String get duplicateFindCandidates;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중...'**
  String get loading;

  /// No description provided for @duplicateLoadMore.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보 더 보기'**
  String get duplicateLoadMore;

  /// No description provided for @duplicateRestoringLastResult.
  ///
  /// In ko, this message translates to:
  /// **'마지막 검사 결과를 불러오고 있어요.'**
  String get duplicateRestoringLastResult;

  /// No description provided for @duplicateSavingResult.
  ///
  /// In ko, this message translates to:
  /// **'검사 결과 저장 중...'**
  String get duplicateSavingResult;

  /// No description provided for @duplicateReanalyzing.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 다시 분석 중...'**
  String get duplicateReanalyzing;

  /// No description provided for @duplicateSavingSafely.
  ///
  /// In ko, this message translates to:
  /// **'검사 결과를 안전하게 저장하고 있어요.'**
  String get duplicateSavingSafely;

  /// No description provided for @duplicateFindingCandidates.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보를 찾고 있어요.'**
  String get duplicateFindingCandidates;

  /// No description provided for @duplicateContinueSoon.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 바로 정리를 계속할 수 있어요.'**
  String get duplicateContinueSoon;

  /// No description provided for @duplicateMayTakeTime.
  ///
  /// In ko, this message translates to:
  /// **'사진이 많을수록 조금 시간이 걸릴 수 있어요.'**
  String get duplicateMayTakeTime;

  /// No description provided for @duplicateKeeperMinimum.
  ///
  /// In ko, this message translates to:
  /// **'보관할 사진은 최소 1장 필요해요.'**
  String get duplicateKeeperMinimum;

  /// No description provided for @purchaseCompletedContinueDelete.
  ///
  /// In ko, this message translates to:
  /// **'구매가 완료됐어요. 삭제를 계속 진행할게요.'**
  String get purchaseCompletedContinueDelete;

  /// No description provided for @deleteCanceledOrFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제가 취소되었거나 실패했어요.'**
  String get deleteCanceledOrFailed;

  /// No description provided for @deletePreparation.
  ///
  /// In ko, this message translates to:
  /// **'삭제 준비'**
  String get deletePreparation;

  /// No description provided for @deletedPhotosMoveToRecentlyDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 사진은 최근 삭제된 항목으로 이동해요.'**
  String get deletedPhotosMoveToRecentlyDeleted;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @unableToCheckSize.
  ///
  /// In ko, this message translates to:
  /// **'용량을 확인하지 못했어요'**
  String get unableToCheckSize;

  /// No description provided for @noPhotosToDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제할 사진 없음'**
  String get noPhotosToDelete;

  /// No description provided for @keep.
  ///
  /// In ko, this message translates to:
  /// **'✓ 보관'**
  String get keep;

  /// No description provided for @deleteCandidate.
  ///
  /// In ko, this message translates to:
  /// **'삭제 후보'**
  String get deleteCandidate;

  /// No description provided for @noRemainingDuplicateCandidates.
  ///
  /// In ko, this message translates to:
  /// **'현재 남아 있는 중복 후보가 없어요'**
  String get noRemainingDuplicateCandidates;

  /// No description provided for @noAnalysisResult.
  ///
  /// In ko, this message translates to:
  /// **'아직 분석 결과가 없어요'**
  String get noAnalysisResult;

  /// No description provided for @scanAgainIfNewPhotos.
  ///
  /// In ko, this message translates to:
  /// **'새로운 사진이 추가되었다면\n다시 검사해주세요.'**
  String get scanAgainIfNewPhotos;

  /// No description provided for @tapFindCandidatesGuide.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보 찾기를 눌러\n사진 보관함을 검사해주세요.'**
  String get tapFindCandidatesGuide;

  /// No description provided for @duplicateSavingWait.
  ///
  /// In ko, this message translates to:
  /// **'검사 결과를 저장하고 있어요. 잠시만 기다려주세요.'**
  String get duplicateSavingWait;

  /// No description provided for @duplicateAnalyzingWait.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진을 분석하고 있어요. 잠시만 기다려주세요.'**
  String get duplicateAnalyzingWait;

  /// No description provided for @duplicateLoadLastResultError.
  ///
  /// In ko, this message translates to:
  /// **'마지막 검사 결과를 불러오지 못했어요: {error}'**
  String duplicateLoadLastResultError(String error);

  /// No description provided for @duplicateLoadMoreError.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보를 더 불러오지 못했어요: {error}'**
  String duplicateLoadMoreError(String error);

  /// No description provided for @duplicateAnalysisError.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 분석 중 문제가 발생했어요: {error}'**
  String duplicateAnalysisError(String error);

  /// No description provided for @duplicateSaveDeleteResultError.
  ///
  /// In ko, this message translates to:
  /// **'삭제 결과를 저장하는 중 문제가 발생했어요: {error}'**
  String duplicateSaveDeleteResultError(String error);

  /// No description provided for @duplicateProgress.
  ///
  /// In ko, this message translates to:
  /// **'{percent}% · {current} / {total} 그룹 분석 중'**
  String duplicateProgress(int percent, int current, int total);

  /// No description provided for @duplicateSummaryPartial.
  ///
  /// In ko, this message translates to:
  /// **'전체 중복 후보 {total}개 그룹\n현재 {visible}개 표시 중 · 삭제 후보 {deleteCount}장'**
  String duplicateSummaryPartial(int total, int visible, int deleteCount);

  /// No description provided for @duplicateSummaryFull.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보 {total}개 그룹\n삭제 후보 {deleteCount}장'**
  String duplicateSummaryFull(int total, int deleteCount);

  /// No description provided for @freeDeleteCompleted.
  ///
  /// In ko, this message translates to:
  /// **'{count}장의 사진을 삭제했어요. 첫 무료 정리를 사용했어요.'**
  String freeDeleteCompleted(int count);

  /// No description provided for @deleteMovedToRecentlyDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{count}장의 사진을 최근 삭제된 항목으로 이동했어요.'**
  String deleteMovedToRecentlyDeleted(int count);

  /// No description provided for @deleteCandidatesReview.
  ///
  /// In ko, this message translates to:
  /// **'삭제 후보 {count}장을 다시 확인해주세요.'**
  String deleteCandidatesReview(int count);

  /// No description provided for @estimatedSpace.
  ///
  /// In ko, this message translates to:
  /// **'예상 확보 공간 {size}'**
  String estimatedSpace(String size);

  /// No description provided for @deleteCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}장 삭제'**
  String deleteCount(int count);

  /// No description provided for @duplicateCandidateCount.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보 {count}장'**
  String duplicateCandidateCount(int count);

  /// No description provided for @keeperAndDeleteCount.
  ///
  /// In ko, this message translates to:
  /// **'보관 {keepCount}장 · 삭제 후보 {deleteCount}장'**
  String keeperAndDeleteCount(int keepCount, int deleteCount);

  /// No description provided for @deletePreparationCount.
  ///
  /// In ko, this message translates to:
  /// **'삭제 준비 ({count}장)'**
  String deletePreparationCount(int count);

  /// No description provided for @homeHeroTitle.
  ///
  /// In ko, this message translates to:
  /// **'아이폰 사진을 정리하고\n저장공간을 되찾아보세요'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진과 불필요한 파일을 찾아\n안전하게 정리할 수 있어요.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeCleanupSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'정리하기'**
  String get homeCleanupSectionTitle;

  /// No description provided for @homeCleanupSectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'저장공간을 차지하는 사진과 영상을 확인해요.'**
  String get homeCleanupSectionSubtitle;

  /// No description provided for @homeScreenshotCleanupTitle.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 정리'**
  String get homeScreenshotCleanupTitle;

  /// No description provided for @homeScreenshotCleanupDescription.
  ///
  /// In ko, this message translates to:
  /// **'오래된 스크린샷을 한곳에서 확인하고 정리해요.'**
  String get homeScreenshotCleanupDescription;

  /// No description provided for @homeLargeVideoCleanupTitle.
  ///
  /// In ko, this message translates to:
  /// **'큰 동영상 정리'**
  String get homeLargeVideoCleanupTitle;

  /// No description provided for @homeLargeVideoCleanupDescription.
  ///
  /// In ko, this message translates to:
  /// **'저장공간을 많이 차지하는 동영상을 용량순으로 확인해요.'**
  String get homeLargeVideoCleanupDescription;

  /// No description provided for @homeAlbumSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 만들기'**
  String get homeAlbumSectionTitle;

  /// No description provided for @homeAlbumSectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사진을 원하는 기준으로 묶어 앨범을 만들어요.'**
  String get homeAlbumSectionSubtitle;

  /// No description provided for @homeDateTimeAlbumTitle.
  ///
  /// In ko, this message translates to:
  /// **'기간·시간별 앨범 만들기'**
  String get homeDateTimeAlbumTitle;

  /// No description provided for @homeDateTimeAlbumDescription.
  ///
  /// In ko, this message translates to:
  /// **'원하는 날짜와 시간대를 골라 앨범을 만들어요.'**
  String get homeDateTimeAlbumDescription;

  /// No description provided for @homeAutoClassificationTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 자동 분류'**
  String get homeAutoClassificationTitle;

  /// No description provided for @homeAutoClassificationDescription.
  ///
  /// In ko, this message translates to:
  /// **'사진을 분석해 주제별 앨범으로 정리해요.'**
  String get homeAutoClassificationDescription;

  /// No description provided for @available.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능'**
  String get available;

  /// No description provided for @beta.
  ///
  /// In ko, this message translates to:
  /// **'Beta'**
  String get beta;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @analysisComplete.
  ///
  /// In ko, this message translates to:
  /// **'분석 완료'**
  String get analysisComplete;

  /// No description provided for @availableNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 사용 가능'**
  String get availableNow;

  /// No description provided for @homeDuplicateLoading.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 정보를 불러오고 있어요.'**
  String get homeDuplicateLoading;

  /// No description provided for @homeDuplicateBeforeScanDescription.
  ///
  /// In ko, this message translates to:
  /// **'사진 보관함에서 중복 사진을 찾아\n확보할 수 있는 공간을 확인해보세요.'**
  String get homeDuplicateBeforeScanDescription;

  /// No description provided for @homeDuplicateCleanDescription.
  ///
  /// In ko, this message translates to:
  /// **'현재 정리할 중복 사진이 없어요.\n사진 보관함이 깔끔해요.'**
  String get homeDuplicateCleanDescription;

  /// No description provided for @homeDuplicateHasCandidatesDescription.
  ///
  /// In ko, this message translates to:
  /// **'비슷한 사진을 찾아 정리해요.'**
  String get homeDuplicateHasCandidatesDescription;

  /// No description provided for @homeFindDuplicates.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 찾아보기'**
  String get homeFindDuplicates;

  /// No description provided for @homeCleanDuplicates.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 정리하기'**
  String get homeCleanDuplicates;

  /// No description provided for @homeStartFirstScan.
  ///
  /// In ko, this message translates to:
  /// **'첫 검사를 시작해보세요'**
  String get homeStartFirstScan;

  /// No description provided for @homeFirstScanDescription.
  ///
  /// In ko, this message translates to:
  /// **'사진을 삭제하지 않고\n중복 후보만 먼저 찾아드려요.'**
  String get homeFirstScanDescription;

  /// No description provided for @homeNoDuplicatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'정리할 중복 사진이 없어요'**
  String get homeNoDuplicatesTitle;

  /// No description provided for @homeNoDuplicatesDescription.
  ///
  /// In ko, this message translates to:
  /// **'지금 사진 보관함은 깔끔한 상태예요.'**
  String get homeNoDuplicatesDescription;

  /// No description provided for @homeGroupCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 그룹'**
  String homeGroupCount(int count);

  /// No description provided for @homeDeleteCandidateCount.
  ///
  /// In ko, this message translates to:
  /// **'삭제 후보 {count}장'**
  String homeDeleteCandidateCount(int count);

  /// No description provided for @homeReclaimableBeforeDelete.
  ///
  /// In ko, this message translates to:
  /// **'확보 용량은 삭제 전에 확인할 수 있어요.'**
  String get homeReclaimableBeforeDelete;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsPhotoCleanupSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 정리'**
  String get settingsPhotoCleanupSectionTitle;

  /// No description provided for @settingsPhotoCleanupSectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 검사 결과를 관리해요.'**
  String get settingsPhotoCleanupSectionSubtitle;

  /// No description provided for @settingsResetDuplicateTitle.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 검사 결과 초기화'**
  String get settingsResetDuplicateTitle;

  /// No description provided for @settingsResetDuplicateSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 결과와 처리 완료 기록을 지우고 다시 검사해요.'**
  String get settingsResetDuplicateSubtitle;

  /// No description provided for @settingsAlbumSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get settingsAlbumSectionTitle;

  /// No description provided for @settingsAlbumSectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 생성되는 앨범 이름을 설정해요.'**
  String get settingsAlbumSectionSubtitle;

  /// No description provided for @settingsAutoAlbumNameTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 분류 앨범 이름'**
  String get settingsAutoAlbumNameTitle;

  /// No description provided for @settingsAutoAlbumNameSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 자동 분류에 사용할 앨범 이름을 변경해요.'**
  String get settingsAutoAlbumNameSubtitle;

  /// No description provided for @settingsAppSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 설정'**
  String get settingsAppSectionTitle;

  /// No description provided for @settingsAppSectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Pomu의 기본 설정을 확인해요.'**
  String get settingsAppSectionSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'현재 아이폰의 앱 언어 설정을 사용해요.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsInfoSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingsInfoSectionTitle;

  /// No description provided for @settingsInfoSectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Pomu에 대한 정보를 확인해요.'**
  String get settingsInfoSectionSubtitle;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리 내용을 확인해요.'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsTermsTitle.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get settingsTermsTitle;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관을 확인해요.'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get settingsContactTitle;

  /// No description provided for @settingsContactSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 이용 중 궁금한 점을 문의해요.'**
  String get settingsContactSubtitle;

  /// No description provided for @settingsAppVersionTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get settingsAppVersionTitle;

  /// No description provided for @comingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중'**
  String get comingSoon;

  /// No description provided for @settingsResetDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'검사 결과를 초기화할까요?'**
  String get settingsResetDialogTitle;

  /// No description provided for @settingsResetDialogDescription.
  ///
  /// In ko, this message translates to:
  /// **'저장된 중복 그룹과 처리 완료 기록을\n초기화하고 처음부터 다시 검사해요.'**
  String get settingsResetDialogDescription;

  /// No description provided for @settingsResetNoticeResolvedGroups.
  ///
  /// In ko, this message translates to:
  /// **'이전에 처리한 그룹도 다시 나타날 수 있어요.'**
  String get settingsResetNoticeResolvedGroups;

  /// No description provided for @settingsResetNoticePhotosSafe.
  ///
  /// In ko, this message translates to:
  /// **'아이폰 사진은 삭제되거나 변경되지 않아요.'**
  String get settingsResetNoticePhotosSafe;

  /// No description provided for @settingsResetNoticePurchaseKept.
  ///
  /// In ko, this message translates to:
  /// **'구매 기록과 무료 이용 기록은 유지돼요.'**
  String get settingsResetNoticePurchaseKept;

  /// No description provided for @settingsResetAction.
  ///
  /// In ko, this message translates to:
  /// **'검사 결과 초기화'**
  String get settingsResetAction;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 검사 결과를 초기화했어요.'**
  String get settingsResetSuccess;

  /// No description provided for @settingsResetFailure.
  ///
  /// In ko, this message translates to:
  /// **'초기화하지 못했어요. 잠시 후 다시 시도해주세요.'**
  String get settingsResetFailure;

  /// No description provided for @purchaseLifetimeBadge.
  ///
  /// In ko, this message translates to:
  /// **'한 번 구매로 영구 이용'**
  String get purchaseLifetimeBadge;

  /// No description provided for @purchaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'중복 사진 정리를\n계속 이용해보세요'**
  String get purchaseTitle;

  /// No description provided for @purchaseDescription.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 중복 그룹은 무료로 정리했어요.\n이제 제한 없이 계속 정리할 수 있어요.'**
  String get purchaseDescription;

  /// No description provided for @purchaseLoadingProduct.
  ///
  /// In ko, this message translates to:
  /// **'상품 정보 확인 중'**
  String get purchaseLoadingProduct;

  /// No description provided for @purchaseOneTimeNoExtraCharge.
  ///
  /// In ko, this message translates to:
  /// **'일회성 결제 · 추가 결제 없음'**
  String get purchaseOneTimeNoExtraCharge;

  /// No description provided for @purchaseBenefitLifetimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'영구 이용'**
  String get purchaseBenefitLifetimeTitle;

  /// No description provided for @purchaseBenefitLifetimeDescription.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 결제'**
  String get purchaseBenefitLifetimeDescription;

  /// No description provided for @purchaseBenefitUnlimitedTitle.
  ///
  /// In ko, this message translates to:
  /// **'무제한 정리'**
  String get purchaseBenefitUnlimitedTitle;

  /// No description provided for @purchaseBenefitUnlimitedDescription.
  ///
  /// In ko, this message translates to:
  /// **'그룹 개수 제한 없음'**
  String get purchaseBenefitUnlimitedDescription;

  /// No description provided for @purchaseBenefitRestoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get purchaseBenefitRestoreTitle;

  /// No description provided for @purchaseBenefitRestoreDescription.
  ///
  /// In ko, this message translates to:
  /// **'재설치 후에도 복원'**
  String get purchaseBenefitRestoreDescription;

  /// No description provided for @purchaseBenefitNoSubscriptionTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 없음'**
  String get purchaseBenefitNoSubscriptionTitle;

  /// No description provided for @purchaseBenefitNoSubscriptionDescription.
  ///
  /// In ko, this message translates to:
  /// **'매달 결제하지 않아요'**
  String get purchaseBenefitNoSubscriptionDescription;

  /// No description provided for @purchaseLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.'**
  String get purchaseLoadFailed;

  /// No description provided for @purchaseReloadProduct.
  ///
  /// In ko, this message translates to:
  /// **'상품 정보 다시 불러오기'**
  String get purchaseReloadProduct;

  /// No description provided for @purchaseRestoring.
  ///
  /// In ko, this message translates to:
  /// **'구매 내역을 확인하고 있어요.'**
  String get purchaseRestoring;

  /// No description provided for @purchaseRestoringShort.
  ///
  /// In ko, this message translates to:
  /// **'구매 내역 확인 중...'**
  String get purchaseRestoringShort;

  /// No description provided for @purchaseWithPrice.
  ///
  /// In ko, this message translates to:
  /// **'{price}으로 영구 이용'**
  String purchaseWithPrice(String price);

  /// No description provided for @screenshotLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷을 불러오지 못했어요.'**
  String get screenshotLoadFailed;

  /// No description provided for @screenshotDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷을 삭제하지 못했어요.'**
  String get screenshotDeleteFailed;

  /// No description provided for @screenshotDeletedSuccess.
  ///
  /// In ko, this message translates to:
  /// **'{count}장의 스크린샷을 최근 삭제된 항목으로 이동했어요.'**
  String screenshotDeletedSuccess(int count);

  /// No description provided for @screenshotDeletePreparationTitle.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 삭제 준비'**
  String get screenshotDeletePreparationTitle;

  /// No description provided for @screenshotDeleteReview.
  ///
  /// In ko, this message translates to:
  /// **'선택한 스크린샷 {count}장을 확인해주세요.'**
  String screenshotDeleteReview(int count);

  /// No description provided for @screenshotMoveToRecentlyDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 항목은 사진 앱의 최근 삭제된 항목으로 이동해요.'**
  String get screenshotMoveToRecentlyDeleted;

  /// No description provided for @screenshotDeselectAll.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get screenshotDeselectAll;

  /// No description provided for @screenshotSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 선택'**
  String get screenshotSelectAll;

  /// No description provided for @deleting.
  ///
  /// In ko, this message translates to:
  /// **'삭제 중...'**
  String get deleting;

  /// No description provided for @screenshotSelectToDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제할 스크린샷을 선택해주세요'**
  String get screenshotSelectToDelete;

  /// No description provided for @screenshotDeleteSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택한 {count}장 삭제'**
  String screenshotDeleteSelected(int count);

  /// No description provided for @screenshotTotalCount.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 {count}장'**
  String screenshotTotalCount(int count);

  /// No description provided for @screenshotSelectToDeleteWithPeriod.
  ///
  /// In ko, this message translates to:
  /// **'삭제할 스크린샷을 선택해주세요.'**
  String get screenshotSelectToDeleteWithPeriod;

  /// No description provided for @screenshotSelectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}장을 선택했어요.'**
  String screenshotSelectedCount(int count);

  /// No description provided for @photoPermissionRequiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 접근 권한이 필요해요'**
  String get photoPermissionRequiredTitle;

  /// No description provided for @screenshotPermissionDescription.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷을 확인하고 정리하려면\n사진 보관함 접근을 허용해주세요.'**
  String get screenshotPermissionDescription;

  /// No description provided for @openSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openSettings;

  /// No description provided for @screenshotLimitedAccessDescription.
  ///
  /// In ko, this message translates to:
  /// **'선택한 사진만 접근 중이에요. 모든 스크린샷을 보려면 접근 사진을 추가해주세요.'**
  String get screenshotLimitedAccessDescription;

  /// No description provided for @addPhotos.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get addPhotos;

  /// No description provided for @screenshotEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'정리할 스크린샷이 없어요'**
  String get screenshotEmptyTitle;

  /// No description provided for @screenshotEmptyDescription.
  ///
  /// In ko, this message translates to:
  /// **'현재 사진 보관함에 스크린샷이 없거나\n접근 가능한 스크린샷이 없어요.'**
  String get screenshotEmptyDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
