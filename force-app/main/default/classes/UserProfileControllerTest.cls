@isTest
private class UserProfileControllerTest {
    @isTest
    static void testGetUserProfile() {
        Test.startTest();
        String profileName = UserProfileController.getUserProfile();
        Test.stopTest();
        System.assertNotEquals(null, profileName, 'le nom du profil ne doit pas être nul');
    }
}
