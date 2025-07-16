@isTest
private class UserProfileControllerTest {

    // Test pour un utilisateur Chatter External
    @isTest
    static void testGetCurrentUserProfile() {
        User testUser = TestDataFactory.createUserWithProfile('Chatter External User');
        System.runAs(testUser) {
            Test.startTest();
            String profileName = UserProfileController.getCurrentUserProfile();
            Test.stopTest();

            System.debug('Profil retourné : ' + profileName);
            System.assertNotEquals(null, profileName, 'Profil ne doit pas être null');
            System.assertNotEquals('', profileName, 'Profil ne doit pas être vide');
            System.assertEquals('Chatter External User', profileName, 'Profil attendu : Chatter External User');
        }
    }

    // Test direct de getCurrentUserProfileInternal sans erreur
    @isTest
    static void testGetCurrentUserProfileInternal_NoError() {
        User testUser = TestDataFactory.createUserWithProfile('Chatter External User');
        System.runAs(testUser) {
            Test.startTest();
            String profileName = UserProfileController.getCurrentUserProfileInternal(false);
            Test.stopTest();

            System.debug('Profil récupéré sans erreur : ' + profileName);
            System.assertEquals('Chatter External User', profileName, 'Profil attendu : Chatter External User');
        }
    }

    // Test de getCurrentUserProfileInternal avec erreur simulée
    @isTest
    static void testGetCurrentUserProfileInternal_Error() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            UserProfileController.getCurrentUserProfileInternal(true);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.debug('Erreur capturée : ' + e.getMessage());
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Exception attendue non levée');
    }

    // Test pour un utilisateur Admin, comparaison par profil Id
    @isTest
    static void testGetCurrentUserProfile_AdminUser() {
        // Récupérer l'Id du profil System Administrator
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User adminUser = TestDataFactory.createUserWithProfile('System Administrator');
        System.runAs(adminUser) {
            Test.startTest();
            String profileName = UserProfileController.getCurrentUserProfile();
            Test.stopTest();

            System.debug('Profil Admin retourné : ' + profileName);

            // Récupérer l'Id du profil retourné
            Profile returnedProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

            System.assertEquals(sysAdminProfile.Id, returnedProfile.Id, 'Le profil retourné doit être System Administrator (par Id)');
        }
    }

    // Test pour un utilisateur commercial (profil Chatter External)
    @isTest
    static void testGetCurrentUserProfile_CommercialUser() {
        User commercialUser = TestDataFactory.createUserWithProfile('Chatter External User');
        System.runAs(commercialUser) {
            Test.startTest();
            String profileName = UserProfileController.getCurrentUserProfile();
            Test.stopTest();

            System.debug('Profil Commercial : ' + profileName);
            System.assertEquals('Chatter External User', profileName, 'Profil attendu : Chatter External User');
        }
    }
}
