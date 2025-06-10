@isTest
private class UserProfileControllerTest {

    @isTest
    static void testGetCurrentUserProfile() {
        User testUser = TestDataFactory.createUserWithProfile('Standard User');
        System.runAs(testUser) {
            Test.startTest();
            String profileName = UserProfileController.getCurrentUserProfile(); 
            Test.stopTest();

            System.debug('🔍 Profil retourné : ' + profileName);
            System.assertNotEquals(null, profileName, 'Le nom du profil ne doit pas être null');
            System.assertNotEquals('', profileName, 'Le nom du profil ne doit pas être vide');
        }
    }

    @isTest
    static void testGetCurrentUserProfileInternal_Error() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            UserProfileController.getCurrentUserProfileInternal(true);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Erreur simulée'), 'Le message d’erreur doit être remonté');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Une exception AuraHandledException était attendue');
    }
}