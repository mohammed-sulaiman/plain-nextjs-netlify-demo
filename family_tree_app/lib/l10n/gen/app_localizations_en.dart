// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Tree';

  @override
  String get aboutText =>
      'Build, explore and share your family tree. Works offline; sign in to sync across devices.';

  @override
  String get account => 'Account';

  @override
  String get add => 'Add';

  @override
  String get addBrother => 'Brother';

  @override
  String get addSister => 'Sister';

  @override
  String get addFather => 'Father';

  @override
  String get addMother => 'Mother';

  @override
  String get addSon => 'Son';

  @override
  String get addDaughter => 'Daughter';

  @override
  String get addHusband => 'Husband';

  @override
  String get addWife => 'Wife';

  @override
  String get addFirstPerson => 'Add the first person';

  @override
  String get addPerson => 'Add person';

  @override
  String get addRelative => 'Add a relative';

  @override
  String get addResidence => 'Add residence';

  @override
  String get editResidence => 'Edit residence';

  @override
  String get ancestorGenerations => 'Ancestor generations';

  @override
  String get descendantGenerations => 'Descendant generations';

  @override
  String get basicInfo => 'Basic information';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarBoth => 'Gregorian and Hijri';

  @override
  String get calendarGregorian => 'Gregorian';

  @override
  String get calendarHijri => 'Hijri';

  @override
  String get cancel => 'Cancel';

  @override
  String get cardContents => 'Show on each card';

  @override
  String get checkEmail => 'Check your email to continue.';

  @override
  String get children => 'Children';

  @override
  String get chooseOtherParent => 'Who is the other parent?';

  @override
  String get choosePerson => 'Choose a person';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get takePhoto => 'Camera';

  @override
  String get removePhoto => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get cloudNotConfigured => 'Cloud sync is not configured';

  @override
  String get cloudNotConfiguredHint =>
      'Build the app with SUPABASE_URL and SUPABASE_ANON_KEY to enable sign-in. Your tree is saved on this device.';

  @override
  String get cloudSynced => 'Saved online';

  @override
  String get localOnly => 'Saved on this device';

  @override
  String get confirm => 'Confirm';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get copied => 'Copied';

  @override
  String get createAccount => 'Create account';

  @override
  String get deceased => 'Deceased';

  @override
  String get deletePerson => 'Delete person';

  @override
  String get displayOptions => 'Display options';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get editMarriage => 'Marriage details';

  @override
  String get editPerson => 'Edit person';

  @override
  String get email => 'Email';

  @override
  String get emptyTitle => 'Start your family tree';

  @override
  String get emptyBody =>
      'Add yourself or an ancestor, then add parents, spouses and children around them.';

  @override
  String get endDate => 'End date';

  @override
  String get evBorn => 'Born';

  @override
  String get evDied => 'Died';

  @override
  String get exportGedcom => 'Export GEDCOM';

  @override
  String get importGedcom => 'Import GEDCOM';

  @override
  String get exportImage => 'Export tree as image';

  @override
  String get exportPdf => 'Export / print PDF';

  @override
  String get faceConsent => 'Allow face similarity comparison';

  @override
  String get faceConsentHint =>
      'Required before this photo can be compared. Get consent from the person (or a guardian).';

  @override
  String get faceFailed => 'Comparison failed';

  @override
  String get faceNoConsent =>
      'This person has no photo or has not consented to face comparison. Edit the person to enable it.';

  @override
  String get faceNoFace => 'No face could be detected in the photo.';

  @override
  String get faceNotConfigured =>
      'Face similarity needs the cloud service. Configure Supabase first.';

  @override
  String get faceNotSignedIn => 'Sign in to use face similarity.';

  @override
  String get facePrivacy =>
      'Photos are sent securely to the comparison service only when you press the button, are not stored by it, and only people who consented are compared.';

  @override
  String get faceSimilarity => 'Face similarity';

  @override
  String get findLookalikes => 'Who looks most alike?';

  @override
  String get familyMap => 'Family map';

  @override
  String get familyName => 'Family name';

  @override
  String get givenName => 'First name';

  @override
  String get female => 'Female';

  @override
  String get male => 'Male';

  @override
  String get unknownGender => 'Unknown';

  @override
  String get gender => 'Gender';

  @override
  String get fieldAge => 'Age';

  @override
  String get fieldBirthDate => 'Date of birth';

  @override
  String get fieldBirthPlace => 'Place of birth';

  @override
  String get fieldDeathDate => 'Date of death';

  @override
  String get fieldKunya => 'Kunya';

  @override
  String get fieldLineage => 'Lineage';

  @override
  String get fieldPhoto => 'Photo';

  @override
  String get fieldResidence => 'Residence';

  @override
  String get fieldTribe => 'Tribe / clan';

  @override
  String get kunyaHint => 'e.g. Abu Mohammed';

  @override
  String get nickname => 'Nickname / title';

  @override
  String get firstPerson => 'First person';

  @override
  String get secondPerson => 'Second person';

  @override
  String get focusLabel => 'Focus';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get geneticRelatedness => 'Genetic relatedness (from the tree)';

  @override
  String get geneticRelatednessHint =>
      'Expected share of DNA inherited from common ancestors, calculated from biological links only. Siblings ≈ 50%, first cousins ≈ 12.5%.';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get noAccount => 'Create a new account';

  @override
  String get importEmpty => 'No people found in the file.';

  @override
  String get importMerge => 'Merge';

  @override
  String get importReplace => 'Replace';

  @override
  String get importTitle => 'Import GEDCOM';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get kindAdoptive => 'Adoptive / guardian';

  @override
  String get kindBiological => 'Biological';

  @override
  String get kindMilk => 'Milk (nursing)';

  @override
  String get language => 'Language';

  @override
  String get lifeEvents => 'Life events';

  @override
  String get lineageSon => 'bin';

  @override
  String get lineageDaughter => 'bint';

  @override
  String get linkExistingChild => 'Link an existing child';

  @override
  String get linkExistingParent => 'Link an existing parent';

  @override
  String get linkExistingSpouse => 'Link an existing spouse';

  @override
  String get linkType => 'Relationship type';

  @override
  String get loadSample => 'Load sample family';

  @override
  String get mahramStatus => 'Mahram status';

  @override
  String get mahramBlood => 'Mahram by lineage (نسب)';

  @override
  String get mahramMilk => 'Mahram by nursing (رضاعة)';

  @override
  String get mahramMarriage => 'Mahram by marriage (مصاهرة)';

  @override
  String get mahramConsummation =>
      'Applies only if the marriage was consummated.';

  @override
  String get mahramDisclaimer =>
      'Calculated only from the relationships recorded in the tree. For guidance only: consult a qualified scholar for rulings.';

  @override
  String get mahramFormerSpouse => 'Former spouse: not mahram';

  @override
  String get mahramSameGender => 'Same gender: not applicable';

  @override
  String get mahramSpouse => 'Spouses';

  @override
  String get mahramUnknownGender => 'Set both genders to calculate';

  @override
  String get notMahram => 'Not mahram';

  @override
  String get marriageDate => 'Marriage date';

  @override
  String get needParentsForSibling =>
      'Add a parent first, then add siblings as their children.';

  @override
  String get noEvents => 'No dated events yet.';

  @override
  String get noMapData =>
      'No residences with a map location yet. Edit a person, add a residence and pick it on the map.';

  @override
  String get noResidences => 'No residences recorded.';

  @override
  String get noResults => 'No results';

  @override
  String get none => 'None recorded';

  @override
  String get notFound => 'Person not found';

  @override
  String get notNow => 'Not now';

  @override
  String get notSet => 'Not set';

  @override
  String get notes => 'Notes';

  @override
  String get openSettings => 'Open settings';

  @override
  String get parents => 'Parents';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'At least 8 characters';

  @override
  String get pickOnMap => 'Pick on map';

  @override
  String get pickTwoPeople => 'Choose two people to see how they are related.';

  @override
  String get placeName => 'Place';

  @override
  String get present => 'present';

  @override
  String get recenter => 'Back to focus';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get relationship => 'Relationship';

  @override
  String get relationshipCalculator => 'Relationship calculator';

  @override
  String get required => 'Required';

  @override
  String get residences => 'Residences';

  @override
  String get save => 'Save';

  @override
  String get saveFailed => 'Could not save';

  @override
  String get search => 'Find a person';

  @override
  String get searchFailed => 'Search failed. Check your connection.';

  @override
  String get searchHint => 'Name, lineage, kunya or tribe';

  @override
  String get searchPlace => 'Search for a city or place';

  @override
  String get setAsFocus => 'Make this person the focus';

  @override
  String get settings => 'Settings';

  @override
  String get showOnMap => 'Map';

  @override
  String get showSiblings => 'Show siblings';

  @override
  String get showSpouses => 'Show spouses';

  @override
  String get showUnclesAunts => 'Show uncles and aunts';

  @override
  String get siblings => 'Siblings';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInHint =>
      'Sign in to save your tree online and open it on all your devices.';

  @override
  String get signOut => 'Sign out';

  @override
  String get spouses => 'Spouses';

  @override
  String get statusDivorced => 'Divorced';

  @override
  String get statusMarried => 'Married';

  @override
  String get statusWidowed => 'Widowed';

  @override
  String get swap => 'Swap';

  @override
  String get systemDefault => 'System';

  @override
  String get theme => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get timeline => 'Timeline';

  @override
  String get treeHint =>
      'Tip: tap a person for options, double-tap to make them the focus, pinch or scroll to zoom.';

  @override
  String get treeScope => 'Who appears in the tree';

  @override
  String get unlink => 'Remove link';

  @override
  String get unlinkConfirm =>
      'Remove this relationship? The people stay in the tree.';

  @override
  String get unnamed => '(no name)';

  @override
  String get upload => 'Upload';

  @override
  String get uploadTitle => 'Upload your tree?';

  @override
  String get viewDetails => 'View details';

  @override
  String ageYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years',
      one: '1 year',
      zero: 'under 1 year',
    );
    return '$_temp0';
  }

  @override
  String diedAged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'died aged $n',
      one: 'died aged 1',
    );
    return '$_temp0';
  }

  @override
  String bornShort(String date) {
    return 'b. $date';
  }

  @override
  String diedShort(String date) {
    return 'd. $date';
  }

  @override
  String commonAncestor(String name) {
    return 'Common ancestor: $name';
  }

  @override
  String deleteConfirm(String name) {
    return 'Delete $name and all of their links?';
  }

  @override
  String evBornIn(String place) {
    return 'Born in $place';
  }

  @override
  String evChildBorn(String name) {
    return 'Birth of $name';
  }

  @override
  String evDivorced(String name) {
    return 'Divorced from $name';
  }

  @override
  String evMarried(String name) {
    return 'Married $name';
  }

  @override
  String evMoved(String place) {
    return 'Moved to $place';
  }

  @override
  String evParentDied(String name) {
    return 'Death of $name';
  }

  @override
  String evWidowed(String name) {
    return 'Widowed: $name';
  }

  @override
  String faceEligible(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count family members can be compared.',
      one: '1 family member can be compared.',
      zero: 'No other family members have consented to comparison yet.',
    );
    return '$_temp0';
  }

  @override
  String focusSet(String name) {
    return '$name is now the focus of the tree';
  }

  @override
  String importDone(int count) {
    return 'Imported $count people';
  }

  @override
  String importQuestion(int count) {
    return 'The file has $count people. Merge them into the current tree or replace it?';
  }

  @override
  String isRelationOf(String b, String relation, String a) {
    return '$b to $a: $relation';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people in this tree',
      one: '1 person in this tree',
    );
    return '$_temp0';
  }

  @override
  String relationTo(String relation, String name) {
    return '$relation of $name';
  }

  @override
  String uploadQuestion(int count) {
    return 'Your cloud tree is empty. Upload the $count people saved on this device?';
  }
}
