import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// IMPORT des custom labels  pour traduire les champs et bouttons (internationalisation)
// Demander en fin du KanBan du projet 
import Label_NomProduit from '@salesforce/label/c.Label_NomProduit';
import Label_Quantite from '@salesforce/label/c.Label_Quantite';
import Label_PrixUnitaire from '@salesforce/label/c.Label_PrixUnitaire';
import Label_PrixTotal from '@salesforce/label/c.Label_PrixTotal';
import Label_QuantiteStock from '@salesforce/label/c.Label_QuantiteStock';
import Label_Supprimer from '@salesforce/label/c.Label_Supprimer';
import Label_VoirProduit from '@salesforce/label/c.Label_VoirProduit';
import Label_MessageStockError from '@salesforce/label/c.Label_MessageStockError';
import Label_OpportunityProduits from '@salesforce/label/c.Label_OpportunityProduits';
import Label_ErreurMajStock from '@salesforce/label/c.Label_ErreurMajStock';
import Label_AucunProduit from '@salesforce/label/c.Label_AucunProduit';

import getOpportunityLineItems from '@salesforce/apex/OpportunityLineItemController.getOpportunityLineItems';
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityLineItemController.deleteOpportunityLineItem';
import getCurrentUserProfile from '@salesforce/apex/UserProfileController.getCurrentUserProfile';

export default class OpportunityProductViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    lineItems = [];
    userProfile = '';
    columns = [];

    //  Exposer les labels pour le HTML
    Label_OpportunityProduits = Label_OpportunityProduits;
    Label_MessageStockError = Label_MessageStockError;
    Label_AucunProduit = Label_AucunProduit;

    // regrouper aussi pour usage JS (datatable)
    label = {
        Label_NomProduit,
        Label_Quantite,
        Label_PrixUnitaire,
        Label_PrixTotal,
        Label_QuantiteStock,
        Label_Supprimer,
        Label_VoirProduit,
        Label_MessageStockError,
        Label_OpportunityProduits,
        Label_ErreurMajStock,
        Label_AucunProduit
    };

    connectedCallback() {
        this.initComponent();  // au demarrage on initie le composant pr charger les données
    } // life cycle hooks

    async initComponent() {
        try {
            this.userProfile = await getCurrentUserProfile(); // recuperer le profil (admin ou commercial)
            this.columns = this.buildColumns(); // construire les colonnes avec les bon labels traduits
            await this.loadLineItems();
        } catch (error) {
            console.error('Erreur d\'initialisation :', error);
            this.showToast('Erreur', 'Échec de l’initialisation du composant', 'error');
        }
    }

    buildColumns() {
        const baseColumns = [
            { label: Label_NomProduit, fieldName: 'productName', type: 'text' },
            { label: Label_Quantite, fieldName: 'quantity', type: 'number',
                cellAttributes: {   // couleur rouge SUR QUANTITE SI stock insuffisant & css inline
                    style: { fieldName: 'stockError' }
                }
            },
            { label: Label_PrixUnitaire, fieldName: 'unitPrice', type: 'currency' },
            { label: Label_PrixTotal, fieldName: 'totalPrice', type: 'currency' },
            { label: Label_QuantiteStock, fieldName: 'quantityInStock', type: 'number' },
            {
                label: Label_Supprimer,
                type: 'button-icon',
                typeAttributes: {
                    iconName: 'utility:delete',
                    name: 'delete',
                    title: Label_Supprimer,
                    variant: 'border-filled',
                    alternativeText: Label_Supprimer
                }
            }
        ];

        // lowercase pour eviter les erreurs de majuscule
        const normalizedProfile = this.userProfile?.toLowerCase();
        if (normalizedProfile === 'system administrator') {
            baseColumns.push({ // Ajouter la colonne VOIR produit uniquement pour les admins
                type: 'button',
                label: Label_VoirProduit,
                typeAttributes: {
                    label: Label_VoirProduit,
                    name: 'view',
                    iconName: 'utility:preview',
                    variant: 'brand'
                }
            });
        }

        return baseColumns;  // retourne les colonnes qu’on va utiliser dans datatable
    }

    async loadLineItems() {
        try {
            const rawItems = await getOpportunityLineItems({ opportunityId: this.recordId });
            this.lineItems = rawItems.map(item => {
                const quantityInStock = item.Product2?.QuantityInStock__c ?? 0;
                return {
                    id: item.Id,
                    quantity: item.Quantity,
                    unitPrice: item.UnitPrice,
                    totalPrice: item.TotalPrice,
                    quantityInStock: quantityInStock,
                    productName: item.Product2?.Name,
                    productId: item.Product2?.Id,
                    stockError: (quantityInStock - item.Quantity) < 0
                        ? 'background-image: repeating-linear-gradient(45deg, #eeeeee, #eeeeee 10px, #dddddd 10px, #dddddd 20px); color: brown; font-weight: bold;'
                        : 'color: darkgreen; font-weight: bold;',
                };
            });
        } catch (error) {
            console.error('Votre opportunité ne peut pas être mise à jour car vous avez un souci de quantité sur vos lignes.', error);
            this.lineItems = [];
        }
    }

    get hasLineItems() { // verifier si ya au moin UNE ligne ou non
        return Array.isArray(this.lineItems) && this.lineItems.length > 0;
    }

    get hasStockError() { // verifie si une ligne a un stock negatif
        return this.lineItems.some(item => (item.quantityInStock - item.quantity) < 0);
    }

    handleRowAction(event) { // LES redirections
        const { name } = event.detail.action;
        const row = event.detail.row;

        if (name === 'delete') {
            this.handleDelete(row);  // quand click SUPPRIMER on supprime la ligne
        } else if (name === 'view') {
            this.handleViewProduct(row); // click VOIR produit > redirige sur la page du produit
        }
    }

    async handleDelete(row) {
        try {
            await deleteOpportunityLineItem({ lineItemId: row.id });
            this.showToast('Succès', 'Ligne supprimée avec succès', 'success');
            await this.loadLineItems(); // recharge la liste apres suppression pour MAJ l'affichage
        } catch (error) {
            this.showToast('Erreur', error.body?.message || 'Erreur inconnue', 'error');
        }
    }

    handleViewProduct(row) {
        if (this.userProfile?.toLowerCase() === 'system administrator') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.productId,
                    objectApiName: 'Product2',
                    actionName: 'view'
                }
            });
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant })); // affiche une notification TOAST
    }
}
