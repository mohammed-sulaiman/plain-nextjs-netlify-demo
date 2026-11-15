import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get appTitle;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Build, explore and share your family tree. Works offline; sign in to sync across devices.'**
  String get aboutText;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get addBrother;

  /// No description provided for @addSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get addSister;

  /// No description provided for @addFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get addFather;

  /// No description provided for @addMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get addMother;

  /// No description provided for @addSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get addSon;

  /// No description provided for @addDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get addDaughter;

  /// No description provided for @addHusband.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get addHusband;

  /// No description provided for @addWife.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get addWife;

  /// No description provided for @addFirstPerson.
  ///
  /// In en, this message translates to:
  /// **'Add the first person'**
  String get addFirstPerson;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// No description provided for @addRelative.
  ///
  /// In en, this message translates to:
  /// **'Add a relative'**
  String get addRelative;

  /// No description provided for @addResidence.
  ///
  /// In en, this message translates to:
  /// **'Add residence'**
  String get addResidence;

  /// No description provided for @editResidence.
  ///
  /// In en, this message translates to:
  /// **'Edit residence'**
  String get editResidence;

  /// No description provided for @ancestorGenerations.
  ///
  /// In en, this message translates to:
  /// **'Ancestor generations'**
  String get ancestorGenerations;

  /// No description provided for @descendantGenerations.
  ///
  /// In en, this message translates to:
  /// **'Descendant generations'**
  String get descendantGenerations;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basicInfo;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarBoth.
  ///
  /// In en, this message translates to:
  /// **'Gregorian and Hijri'**
  String get calendarBoth;

  /// No description provided for @calendarGregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get calendarGregorian;

  /// No description provided for @calendarHijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri'**
  String get calendarHijri;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cardContents.
  ///
  /// In en, this message translates to:
  /// **'Show on each card'**
  String get cardContents;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to continue.'**
  String get checkEmail;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @chooseOtherParent.
  ///
  /// In en, this message translates to:
  /// **'Who is the other parent?'**
  String get chooseOtherParent;

  /// No description provided for @choosePerson.
  ///
  /// In en, this message translates to:
  /// **'Choose a person'**
  String get choosePerson;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get takePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cloudNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync is not configured'**
  String get cloudNotConfigured;

  /// No description provided for @cloudNotConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'Build the app with SUPABASE_URL and SUPABASE_ANON_KEY to enable sign-in. Your tree is saved on this device.'**
  String get cloudNotConfiguredHint;

  /// No description provided for @cloudSynced.
  ///
  /// In en, this message translates to:
  /// **'Saved online'**
  String get cloudSynced;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get localOnly;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @deceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get deceased;

  /// No description provided for @deletePerson.
  ///
  /// In en, this message translates to:
  /// **'Delete person'**
  String get deletePerson;

  /// No description provided for @displayOptions.
  ///
  /// In en, this message translates to:
  /// **'Display options'**
  String get displayOptions;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editMarriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage details'**
  String get editMarriage;

  /// No description provided for @editPerson.
  ///
  /// In en, this message translates to:
  /// **'Edit person'**
  String get editPerson;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your family tree'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add yourself or an ancestor, then add parents, spouses and children around them.'**
  String get emptyBody;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @evBorn.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get evBorn;

  /// No description provided for @evDied.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get evDied;

  /// No description provided for @exportGedcom.
  ///
  /// In en, this message translates to:
  /// **'Export GEDCOM'**
  String get exportGedcom;

  /// No description provided for @importGedcom.
  ///
  /// In en, this message translates to:
  /// **'Import GEDCOM'**
  String get importGedcom;

  /// No description provided for @exportImage.
  ///
  /// In en, this message translates to:
  /// **'Export tree as image'**
  String get exportImage;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export / print PDF'**
  String get exportPdf;

  /// No description provided for @faceConsent.
  ///
  /// In en, this message translates to:
  /// **'Allow face similarity comparison'**
  String get faceConsent;

  /// No description provided for @faceConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Required before this photo can be compared. Get consent from the person (or a guardian).'**
  String get faceConsentHint;

  /// No description provided for @faceFailed.
  ///
  /// In en, this message translates to:
  /// **'Comparison failed'**
  String get faceFailed;

  /// No description provided for @faceNoConsent.
  ///
  /// In en, this message translates to:
  /// **'This person has no photo or has not consented to face comparison. Edit the person to enable it.'**
  String get faceNoConsent;

  /// No description provided for @faceNoFace.
  ///
  /// In en, this message translates to:
  /// **'No face could be detected in the photo.'**
  String get faceNoFace;

  /// No description provided for @faceNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Face similarity needs the cloud service. Configure Supabase first.'**
  String get faceNotConfigured;

  /// No description provided for @faceNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use face similarity.'**
  String get faceNotSignedIn;

  /// No description provided for @facePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Photos are sent securely to the comparison service only when you press the button, are not stored by it, and only people who consented are compared.'**
  String get facePrivacy;

  /// No description provided for @faceSimilarity.
  ///
  /// In en, this message translates to:
  /// **'Face similarity'**
  String get faceSimilarity;

  /// No description provided for @findLookalikes.
  ///
  /// In en, this message translates to:
  /// **'Who looks most alike?'**
  String get findLookalikes;

  /// No description provided for @familyMap.
  ///
  /// In en, this message translates to:
  /// **'Family map'**
  String get familyMap;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyName;

  /// No description provided for @givenName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get givenName;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @unknownGender.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownGender;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @fieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get fieldAge;

  /// No description provided for @fieldBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fieldBirthDate;

  /// No description provided for @fieldBirthPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get fieldBirthPlace;

  /// No description provided for @fieldDeathDate.
  ///
  /// In en, this message translates to:
  /// **'Date of death'**
  String get fieldDeathDate;

  /// No description provided for @fieldKunya.
  ///
  /// In en, this message translates to:
  /// **'Kunya'**
  String get fieldKunya;

  /// No description provided for @fieldLineage.
  ///
  /// In en, this message translates to:
  /// **'Lineage'**
  String get fieldLineage;

  /// No description provided for @fieldPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get fieldPhoto;

  /// No description provided for @fieldResidence.
  ///
  /// In en, this message translates to:
  /// **'Residence'**
  String get fieldResidence;

  /// No description provided for @fieldTribe.
  ///
  /// In en, this message translates to:
  /// **'Tribe / clan'**
  String get fieldTribe;

  /// No description provided for @kunyaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Abu Mohammed'**
  String get kunyaHint;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname / title'**
  String get nickname;

  /// No description provided for @firstPerson.
  ///
  /// In en, this message translates to:
  /// **'First person'**
  String get firstPerson;

  /// No description provided for @secondPerson.
  ///
  /// In en, this message translates to:
  /// **'Second person'**
  String get secondPerson;

  /// No description provided for @focusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @geneticRelatedness.
  ///
  /// In en, this message translates to:
  /// **'Genetic relatedness (from the tree)'**
  String get geneticRelatedness;

  /// No description provided for @geneticRelatednessHint.
  ///
  /// In en, this message translates to:
  /// **'Expected share of DNA inherited from common ancestors, calculated from biological links only. Siblings ≈ 50%, first cousins ≈ 12.5%.'**
  String get geneticRelatednessHint;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get noAccount;

  /// No description provided for @importEmpty.
  ///
  /// In en, this message translates to:
  /// **'No people found in the file.'**
  String get importEmpty;

  /// No description provided for @importMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get importMerge;

  /// No description provided for @importReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get importReplace;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import GEDCOM'**
  String get importTitle;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @kindAdoptive.
  ///
  /// In en, this message translates to:
  /// **'Adoptive / guardian'**
  String get kindAdoptive;

  /// No description provided for @kindBiological.
  ///
  /// In en, this message translates to:
  /// **'Biological'**
  String get kindBiological;

  /// No description provided for @kindMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk (nursing)'**
  String get kindMilk;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lifeEvents.
  ///
  /// In en, this message translates to:
  /// **'Life events'**
  String get lifeEvents;

  /// No description provided for @lineageSon.
  ///
  /// In en, this message translates to:
  /// **'bin'**
  String get lineageSon;

  /// No description provided for @lineageDaughter.
  ///
  /// In en, this message translates to:
  /// **'bint'**
  String get lineageDaughter;

  /// No description provided for @linkExistingChild.
  ///
  /// In en, this message translates to:
  /// **'Link an existing child'**
  String get linkExistingChild;

  /// No description provided for @linkExistingParent.
  ///
  /// In en, this message translates to:
  /// **'Link an existing parent'**
  String get linkExistingParent;

  /// No description provided for @linkExistingSpouse.
  ///
  /// In en, this message translates to:
  /// **'Link an existing spouse'**
  String get linkExistingSpouse;

  /// No description provided for @linkType.
  ///
  /// In en, this message translates to:
  /// **'Relationship type'**
  String get linkType;

  /// No description provided for @loadSample.
  ///
  /// In en, this message translates to:
  /// **'Load sample family'**
  String get loadSample;

  /// No description provided for @mahramStatus.
  ///
  /// In en, this message translates to:
  /// **'Mahram status'**
  String get mahramStatus;

  /// No description provided for @mahramBlood.
  ///
  /// In en, this message translates to:
  /// **'Mahram by lineage (نسب)'**
  String get mahramBlood;

  /// No description provided for @mahramMilk.
  ///
  /// In en, this message translates to:
  /// **'Mahram by nursing (رضاعة)'**
  String get mahramMilk;

  /// No description provided for @mahramMarriage.
  ///
  /// In en, this message translates to:
  /// **'Mahram by marriage (مصاهرة)'**
  String get mahramMarriage;

  /// No description provided for @mahramConsummation.
  ///
  /// In en, this message translates to:
  /// **'Applies only if the marriage was consummated.'**
  String get mahramConsummation;

  /// No description provided for @mahramDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Calculated only from the relationships recorded in the tree. For guidance only: consult a qualified scholar for rulings.'**
  String get mahramDisclaimer;

  /// No description provided for @mahramFormerSpouse.
  ///
  /// In en, this message translates to:
  /// **'Former spouse: not mahram'**
  String get mahramFormerSpouse;

  /// No description provided for @mahramSameGender.
  ///
  /// In en, this message translates to:
  /// **'Same gender: not applicable'**
  String get mahramSameGender;

  /// No description provided for @mahramSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouses'**
  String get mahramSpouse;

  /// No description provided for @mahramUnknownGender.
  ///
  /// In en, this message translates to:
  /// **'Set both genders to calculate'**
  String get mahramUnknownGender;

  /// No description provided for @notMahram.
  ///
  /// In en, this message translates to:
  /// **'Not mahram'**
  String get notMahram;

  /// No description provided for @marriageDate.
  ///
  /// In en, this message translates to:
  /// **'Marriage date'**
  String get marriageDate;

  /// No description provided for @needParentsForSibling.
  ///
  /// In en, this message translates to:
  /// **'Add a parent first, then add siblings as their children.'**
  String get needParentsForSibling;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No dated events yet.'**
  String get noEvents;

  /// No description provided for @noMapData.
  ///
  /// In en, this message translates to:
  /// **'No residences with a map location yet. Edit a person, add a residence and pick it on the map.'**
  String get noMapData;

  /// No description provided for @noResidences.
  ///
  /// In en, this message translates to:
  /// **'No residences recorded.'**
  String get noResidences;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None recorded'**
  String get none;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Person not found'**
  String get notFound;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickOnMap;

  /// No description provided for @pickTwoPeople.
  ///
  /// In en, this message translates to:
  /// **'Choose two people to see how they are related.'**
  String get pickTwoPeople;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeName;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'present'**
  String get present;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Back to focus'**
  String get recenter;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @relationshipCalculator.
  ///
  /// In en, this message translates to:
  /// **'Relationship calculator'**
  String get relationshipCalculator;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @residences.
  ///
  /// In en, this message translates to:
  /// **'Residences'**
  String get residences;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get saveFailed;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Find a person'**
  String get search;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection.'**
  String get searchFailed;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, lineage, kunya or tribe'**
  String get searchHint;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or place'**
  String get searchPlace;

  /// No description provided for @setAsFocus.
  ///
  /// In en, this message translates to:
  /// **'Make this person the focus'**
  String get setAsFocus;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get showOnMap;

  /// No description provided for @showSiblings.
  ///
  /// In en, this message translates to:
  /// **'Show siblings'**
  String get showSiblings;

  /// No description provided for @showSpouses.
  ///
  /// In en, this message translates to:
  /// **'Show spouses'**
  String get showSpouses;

  /// No description provided for @showUnclesAunts.
  ///
  /// In en, this message translates to:
  /// **'Show uncles and aunts'**
  String get showUnclesAunts;

  /// No description provided for @siblings.
  ///
  /// In en, this message translates to:
  /// **'Siblings'**
  String get siblings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your tree online and open it on all your devices.'**
  String get signInHint;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @spouses.
  ///
  /// In en, this message translates to:
  /// **'Spouses'**
  String get spouses;

  /// No description provided for @statusDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get statusDivorced;

  /// No description provided for @statusMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get statusMarried;

  /// No description provided for @statusWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get statusWidowed;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @treeHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: tap a person for options, double-tap to make them the focus, pinch or scroll to zoom.'**
  String get treeHint;

  /// No description provided for @treeScope.
  ///
  /// In en, this message translates to:
  /// **'Who appears in the tree'**
  String get treeScope;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get unlink;

  /// No description provided for @unlinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this relationship? The people stay in the tree.'**
  String get unlinkConfirm;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'(no name)'**
  String get unnamed;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your tree?'**
  String get uploadTitle;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{under 1 year} =1{1 year} other{{n} years}}'**
  String ageYears(int n);

  /// No description provided for @diedAged.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{died aged 1} other{died aged {n}}}'**
  String diedAged(int n);

  /// No description provided for @bornShort.
  ///
  /// In en, this message translates to:
  /// **'b. {date}'**
  String bornShort(String date);

  /// No description provided for @diedShort.
  ///
  /// In en, this message translates to:
  /// **'d. {date}'**
  String diedShort(String date);

  /// No description provided for @commonAncestor.
  ///
  /// In en, this message translates to:
  /// **'Common ancestor: {name}'**
  String commonAncestor(String name);

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and all of their links?'**
  String deleteConfirm(String name);

  /// No description provided for @evBornIn.
  ///
  /// In en, this message translates to:
  /// **'Born in {place}'**
  String evBornIn(String place);

  /// No description provided for @evChildBorn.
  ///
  /// In en, this message translates to:
  /// **'Birth of {name}'**
  String evChildBorn(String name);

  /// No description provided for @evDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced from {name}'**
  String evDivorced(String name);

  /// No description provided for @evMarried.
  ///
  /// In en, this message translates to:
  /// **'Married {name}'**
  String evMarried(String name);

  /// No description provided for @evMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {place}'**
  String evMoved(String place);

  /// No description provided for @evParentDied.
  ///
  /// In en, this message translates to:
  /// **'Death of {name}'**
  String evParentDied(String name);

  /// No description provided for @evWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed: {name}'**
  String evWidowed(String name);

  /// No description provided for @faceEligible.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No other family members have consented to comparison yet.} =1{1 family member can be compared.} other{{count} family members can be compared.}}'**
  String faceEligible(int count);

  /// No description provided for @focusSet.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the focus of the tree'**
  String focusSet(String name);

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} people'**
  String importDone(int count);

  /// No description provided for @importQuestion.
  ///
  /// In en, this message translates to:
  /// **'The file has {count} people. Merge them into the current tree or replace it?'**
  String importQuestion(int count);

  /// No description provided for @isRelationOf.
  ///
  /// In en, this message translates to:
  /// **'{b} to {a}: {relation}'**
  String isRelationOf(String b, String relation, String a);

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person in this tree} other{{count} people in this tree}}'**
  String peopleCount(int count);

  /// No description provided for @relationTo.
  ///
  /// In en, this message translates to:
  /// **'{relation} of {name}'**
  String relationTo(String relation, String name);

  /// No description provided for @uploadQuestion.
  ///
  /// In en, this message translates to:
  /// **'Your cloud tree is empty. Upload the {count} people saved on this device?'**
  String uploadQuestion(int count);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
