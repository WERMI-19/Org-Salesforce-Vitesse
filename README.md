# Projet Salesforce Vitesse – README

---

##  Description

Ce projet Salesforce simule une application de gestion de ventes de véhicules électriques pour l’entreprise fictive **Vitesse**. Il intègre des composants personnalisés, des automatisations métier, des règles de stock, et une interface interactive via LWC.

---

## Cloner et ouvrir le projet localement

Vous pouvez cloner ce projet Salesforce avec la **l'interface `sf CLI`** :

### Avec Salesforce CLI (nouvelle version `sf`)
```bash
sf project generate --name vitesse
cd vitesse
git clone <https://github.com/WERMI-19/Org-Salesforce-Vitesse> .
```

### Deployer le porjet via Visual Studio Code
```bash
sf login org
sf project deploy start --source-dir force-app --target-org vitesse
```

## ⚙️ Fonctionnalités métier

###  Gestion des opportunités fermées gagnées
- Vérifie que les quantités demandées sont disponibles en stock.
- Si une ligne dépasse le stock disponible → blocage avec un message utilisateur.
- La mise à jour du stock est ensuite déléguée à un **Flow RTF automatique** dans l'organisation.

**Un Record Trigger Flow via Apex Trigger pour gerer les erreurs de stockt et notifier l'erreur**


## 🌍 Internationalisation

- Tous les textes affichés sont gérés via **étiquettes personnalisées multilingues**.
- Disponible en français et en anglais.
- Les labels sont stockés dans :
  ```
  /labels/CustomLabels.labels-meta.xml
  ```

---

## 📁 Structure du projet

```
/classes
  - OpportunityHandler.cls
  - OpportunityHandlerTest.cls
  - OpportunityLineItemController.cls
  - OpportunityLineItemControllerTest.cls
  - UserProfileController.cls
  - UserProfileControllerTest.cls

/triggers
  - OpportunityTrigger.trigger

/lwc
  - OpportunityProductViewer
  - ProductListViewer

/objects
  - Product2
    - QuantityInStock__c (Champ personnalisé)

/labels
  - CustomLabels.labels-meta.xml
```

---

##  Composant LWC interactif
- Affiche dynamiquement les lignes de produit d’une opportunité.
- Affiche la colonne stock en rouge si insuffisance.
- Boutons d'action (Supprimer / Voir produit) selon le profil utilisateur.
- Affichage conditionnel de messages personnalisés.

---

## 🧪 Tests Apex

### Couverture unitaire
| Classe                          | Couverture attendue |
|----------------------------------|----------------------|
| OpportunityHandler               | 100% (via trigger)   |
| OpportunityLineItemController    | 100%                 |
| UserProfileController            |  100%                |

### Test d’intégration (via Execute Anonymous)

```apex
// Inclut : création produit, opportunité, update stock, suppression ligne
// Permet de tester l'ensemble du fonctionnement sans UI
```

---

## 🔒 Contrôle d'accès

- **Administrateurs** :
  - Peuvent voir et modifier les stocks
  - Accès aux deux boutons (Supprimer, Voir produit)

- **Commerciaux** :
  - Ne peuvent pas voir le bouton "Voir produit"
  - Champ `QuantityInStock__c` est en lecture seule

---

## 👤 Auteur

- Projet réalisé par : *WERMI ADAMA*
- date de réalisation: Mai 2025
- Contact : *adamalivres19@gmail.com*
