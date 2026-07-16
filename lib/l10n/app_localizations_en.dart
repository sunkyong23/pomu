// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pomu';

  @override
  String get duplicateCleanupTitle => 'Duplicate Photo Cleanup';

  @override
  String get later => 'Not now';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get oneTimePurchase =>
      'This is a one-time purchase, not a subscription.';

  @override
  String get paymentThroughApple =>
      'Payment is processed through your Apple ID.';

  @override
  String get duplicateIntroTitle => 'Let’s find photos\nthat look alike first.';

  @override
  String get duplicateIntroDescription =>
      'Nothing is deleted yet. Review which photos to keep and which are deletion candidates.';

  @override
  String get duplicateSavingShort => 'Saving results...';

  @override
  String get duplicateAnalyzingShort => 'Analyzing...';

  @override
  String get duplicateScanAgain => 'Scan Again';

  @override
  String get duplicateFindCandidates => 'Find Duplicates';

  @override
  String get loading => 'Loading...';

  @override
  String get duplicateLoadMore => 'Show More Duplicates';

  @override
  String get duplicateRestoringLastResult =>
      'Loading your latest scan results.';

  @override
  String get duplicateSavingResult => 'Saving Scan Results...';

  @override
  String get duplicateReanalyzing => 'Reanalyzing Duplicate Photos...';

  @override
  String get duplicateSavingSafely => 'Safely saving your scan results.';

  @override
  String get duplicateFindingCandidates => 'Finding duplicate candidates.';

  @override
  String get duplicateContinueSoon => 'You can continue cleaning up shortly.';

  @override
  String get duplicateMayTakeTime =>
      'This may take a little longer if you have many photos.';

  @override
  String get duplicateKeeperMinimum => 'Keep at least one photo.';

  @override
  String get purchaseCompletedContinueDelete =>
      'Purchase complete. Continuing with deletion.';

  @override
  String get deleteCanceledOrFailed => 'Deletion was canceled or failed.';

  @override
  String get deletePreparation => 'Review Deletion';

  @override
  String get deletedPhotosMoveToRecentlyDeleted =>
      'Deleted photos are moved to Recently Deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get unableToCheckSize => 'Unable to check size';

  @override
  String get noPhotosToDelete => 'No Photos to Delete';

  @override
  String get keep => '✓ Keep';

  @override
  String get deleteCandidate => 'Delete';

  @override
  String get noRemainingDuplicateCandidates => 'No duplicate candidates remain';

  @override
  String get noAnalysisResult => 'No scan results yet';

  @override
  String get scanAgainIfNewPhotos => 'Scan again if you’ve added new photos.';

  @override
  String get tapFindCandidatesGuide =>
      'Tap Find Duplicates to scan your photo library.';

  @override
  String get duplicateSavingWait => 'Saving scan results. Please wait.';

  @override
  String get duplicateAnalyzingWait =>
      'Analyzing duplicate photos. Please wait.';

  @override
  String duplicateLoadLastResultError(String error) {
    return 'Couldn’t load the latest scan result: $error';
  }

  @override
  String duplicateLoadMoreError(String error) {
    return 'Couldn’t load more duplicate candidates: $error';
  }

  @override
  String duplicateAnalysisError(String error) {
    return 'A problem occurred while analyzing duplicate photos: $error';
  }

  @override
  String duplicateSaveDeleteResultError(String error) {
    return 'A problem occurred while saving deletion results: $error';
  }

  @override
  String duplicateProgress(int percent, int current, int total) {
    return '$percent% · $current / $total groups analyzed';
  }

  @override
  String duplicateSummaryPartial(int total, int visible, int deleteCount) {
    return '$total duplicate groups total\nShowing $visible · $deleteCount deletion candidates';
  }

  @override
  String duplicateSummaryFull(int total, int deleteCount) {
    return '$total duplicate groups\n$deleteCount deletion candidates';
  }

  @override
  String freeDeleteCompleted(int count) {
    return 'Deleted $count photos. Your free cleanup has been used.';
  }

  @override
  String deleteMovedToRecentlyDeleted(int count) {
    return 'Moved $count photos to Recently Deleted.';
  }

  @override
  String deleteCandidatesReview(int count) {
    return 'Review $count photos selected for deletion.';
  }

  @override
  String estimatedSpace(String size) {
    return 'Estimated space saved: $size';
  }

  @override
  String deleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String duplicateCandidateCount(int count) {
    return '$count duplicate candidates';
  }

  @override
  String keeperAndDeleteCount(int keepCount, int deleteCount) {
    return 'Keep $keepCount · Delete $deleteCount';
  }

  @override
  String deletePreparationCount(int count) {
    return 'Review Deletion ($count)';
  }

  @override
  String get homeHeroTitle =>
      'Clean up your iPhone photos\nand free up storage';

  @override
  String get homeHeroSubtitle =>
      'Find duplicate photos and unnecessary files,\nthen clean them up safely.';

  @override
  String get homeCleanupSectionTitle => 'Clean Up';

  @override
  String get homeCleanupSectionSubtitle =>
      'Review photos and videos taking up storage.';

  @override
  String get homeScreenshotCleanupTitle => 'Screenshot Cleanup';

  @override
  String get homeScreenshotCleanupDescription =>
      'Review and remove old screenshots in one place.';

  @override
  String get homeLargeVideoCleanupTitle => 'Large Video Cleanup';

  @override
  String get homeLargeVideoCleanupDescription =>
      'Find videos using the most storage, sorted by size.';

  @override
  String get homeAlbumSectionTitle => 'Create Albums';

  @override
  String get homeAlbumSectionSubtitle =>
      'Group photos by the criteria you choose.';

  @override
  String get homeDateTimeAlbumTitle => 'Create Album by Date & Time';

  @override
  String get homeDateTimeAlbumDescription =>
      'Choose a date range and time of day to create an album.';

  @override
  String get homeAutoClassificationTitle => 'Automatic Photo Sorting';

  @override
  String get homeAutoClassificationDescription =>
      'Analyze photos and organize them into themed albums.';

  @override
  String get available => 'Available';

  @override
  String get beta => 'Beta';

  @override
  String get settings => 'Settings';

  @override
  String get analysisComplete => 'Scan Complete';

  @override
  String get availableNow => 'Available Now';

  @override
  String get homeDuplicateLoading => 'Loading duplicate photo information.';

  @override
  String get homeDuplicateBeforeScanDescription =>
      'Find duplicate photos in your library\nand see how much space you could free.';

  @override
  String get homeDuplicateCleanDescription =>
      'There are no duplicate photos to clean up.\nYour photo library looks tidy.';

  @override
  String get homeDuplicateHasCandidatesDescription =>
      'Find and clean up similar photos.';

  @override
  String get homeFindDuplicates => 'Find Duplicate Photos';

  @override
  String get homeCleanDuplicates => 'Clean Up Duplicates';

  @override
  String get homeStartFirstScan => 'Start Your First Scan';

  @override
  String get homeFirstScanDescription =>
      'Nothing will be deleted.\nWe’ll find duplicate candidates first.';

  @override
  String get homeNoDuplicatesTitle => 'No Duplicates to Clean Up';

  @override
  String get homeNoDuplicatesDescription =>
      'Your photo library is currently tidy.';

  @override
  String homeGroupCount(int count) {
    return '$count groups';
  }

  @override
  String homeDeleteCandidateCount(int count) {
    return '$count deletion candidates';
  }

  @override
  String get homeReclaimableBeforeDelete =>
      'You can review the estimated space before deleting.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPhotoCleanupSectionTitle => 'Photo Cleanup';

  @override
  String get settingsPhotoCleanupSectionSubtitle =>
      'Manage saved scan results.';

  @override
  String get settingsResetDuplicateTitle => 'Reset Duplicate Scan Results';

  @override
  String get settingsResetDuplicateSubtitle =>
      'Clear saved results and completed-group history, then scan again.';

  @override
  String get settingsAlbumSectionTitle => 'Albums';

  @override
  String get settingsAlbumSectionSubtitle =>
      'Choose names for automatically created albums.';

  @override
  String get settingsAutoAlbumNameTitle => 'Automatic Sorting Album Names';

  @override
  String get settingsAutoAlbumNameSubtitle =>
      'Change the album names used for automatic photo sorting.';

  @override
  String get settingsAppSectionTitle => 'App Settings';

  @override
  String get settingsAppSectionSubtitle => 'Review Pomu’s basic settings.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Uses the language selected for Pomu in iPhone Settings.';

  @override
  String get settingsInfoSectionTitle => 'App Information';

  @override
  String get settingsInfoSectionSubtitle => 'View information about Pomu.';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'Review how personal information is handled.';

  @override
  String get settingsTermsTitle => 'Terms of Use';

  @override
  String get settingsTermsSubtitle => 'Review the terms for using the service.';

  @override
  String get settingsContactTitle => 'Contact Us';

  @override
  String get settingsContactSubtitle => 'Ask a question about using the app.';

  @override
  String get settingsAppVersionTitle => 'App Version';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get settingsResetDialogTitle => 'Reset scan results?';

  @override
  String get settingsResetDialogDescription =>
      'Clear saved duplicate groups and completed-group history,\nthen start a fresh scan.';

  @override
  String get settingsResetNoticeResolvedGroups =>
      'Previously completed groups may appear again.';

  @override
  String get settingsResetNoticePhotosSafe =>
      'Photos on your iPhone will not be deleted or changed.';

  @override
  String get settingsResetNoticePurchaseKept =>
      'Purchase history and free-use history will be kept.';

  @override
  String get settingsResetAction => 'Reset Scan Results';

  @override
  String get settingsResetSuccess => 'Duplicate photo scan results were reset.';

  @override
  String get settingsResetFailure =>
      'Couldn’t reset the results. Please try again shortly.';

  @override
  String get purchaseLifetimeBadge => 'Lifetime access with one purchase';

  @override
  String get purchaseTitle => 'Keep using\nDuplicate Photo Cleanup';

  @override
  String get purchaseDescription =>
      'Your first duplicate group was cleaned up for free.\nContinue without limits.';

  @override
  String get purchaseLoadingProduct => 'Checking product information';

  @override
  String get purchaseOneTimeNoExtraCharge =>
      'One-time payment · No extra charges';

  @override
  String get purchaseBenefitLifetimeTitle => 'Lifetime Access';

  @override
  String get purchaseBenefitLifetimeDescription => 'Pay only once';

  @override
  String get purchaseBenefitUnlimitedTitle => 'Unlimited Cleanup';

  @override
  String get purchaseBenefitUnlimitedDescription => 'No group limit';

  @override
  String get purchaseBenefitRestoreTitle => 'Restore Purchase';

  @override
  String get purchaseBenefitRestoreDescription => 'Restore after reinstalling';

  @override
  String get purchaseBenefitNoSubscriptionTitle => 'No Subscription';

  @override
  String get purchaseBenefitNoSubscriptionDescription => 'No monthly payments';

  @override
  String get purchaseLoadFailed =>
      'Couldn’t load the product information. Please try again shortly.';

  @override
  String get purchaseReloadProduct => 'Reload Product Information';

  @override
  String get purchaseRestoring => 'Checking your purchase history.';

  @override
  String get purchaseRestoringShort => 'Checking purchases...';

  @override
  String purchaseWithPrice(String price) {
    return 'Get lifetime access for $price';
  }

  @override
  String get screenshotLoadFailed => 'Couldn’t load your screenshots.';

  @override
  String get screenshotDeleteFailed => 'Couldn’t delete the screenshots.';

  @override
  String screenshotDeletedSuccess(int count) {
    return 'Moved $count screenshots to Recently Deleted.';
  }

  @override
  String get screenshotDeletePreparationTitle => 'Review Screenshot Deletion';

  @override
  String screenshotDeleteReview(int count) {
    return 'Review the $count selected screenshots.';
  }

  @override
  String get screenshotMoveToRecentlyDeleted =>
      'Deleted items will be moved to Recently Deleted in Photos.';

  @override
  String get screenshotDeselectAll => 'Deselect All';

  @override
  String get screenshotSelectAll => 'Select All';

  @override
  String get deleting => 'Deleting...';

  @override
  String get screenshotSelectToDelete => 'Select screenshots to delete';

  @override
  String screenshotDeleteSelected(int count) {
    return 'Delete $count Selected';
  }

  @override
  String screenshotTotalCount(int count) {
    return '$count screenshots';
  }

  @override
  String get screenshotSelectToDeleteWithPeriod =>
      'Select screenshots to delete.';

  @override
  String screenshotSelectedCount(int count) {
    return '$count selected.';
  }

  @override
  String get photoPermissionRequiredTitle => 'Photo Access Required';

  @override
  String get screenshotPermissionDescription =>
      'Allow access to your photo library\nto review and clean up screenshots.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get screenshotLimitedAccessDescription =>
      'Pomu can access only selected photos. Add more photos to view all screenshots.';

  @override
  String get addPhotos => 'Add';

  @override
  String get screenshotEmptyTitle => 'No Screenshots to Clean Up';

  @override
  String get screenshotEmptyDescription =>
      'There are no screenshots in your library,\nor none are currently accessible.';
}
