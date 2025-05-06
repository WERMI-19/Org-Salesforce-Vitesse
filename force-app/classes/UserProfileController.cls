public with sharing class UserProfileController {
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfile() {
        try {
            return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération du profil utilisateur : ' + e.getMessage());
        }
    }
}
