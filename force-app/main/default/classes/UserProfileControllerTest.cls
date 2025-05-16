//test unitaire pour  vérifier que la méthode getCurrentUserProfile() retourne bien
// un nom de profil non nul pour l’utilisateur de test actuel.
@isTest
private class UserProfileControllerTest {
    @isTest
    static void testGetCurrentUserProfile() {
        Test.startTest();
        String profileName = UserProfileController.getCurrentUserProfile(); 
        Test.stopTest();
        
        // Vérif que le profil a bien été récupéré
        System.assertNotEquals(null, profileName, 'Le nom du profil ne doit pas être nul');
    }
}
