import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOpportunityLineItems from '@salesforce/apex/OpportunityLineItemController.getOpportunityLineItems';
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityLineItemController.deleteOpportunityLineItem';
import getCurrentUserProfile from '@salesforce/apex/UserProfileController.getCurrentUserProfile';

export default class OpportunityProductViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    lineItems = [];
    userProfile = '';
    columns = [];

    connectedCallback() {
        this.initComponent();
    }
    async initComponent() {
        try {
            this.userProfile = await getCurrentUserProfile(); // Peut échouer
            this.columns = this.buildColumns();
            await this.loadLineItems(); // Peut échouer aussi
        } catch (error) {
            console.error('Erreur d\'initialisation :', error);
            this.showToast('Erreur', 'Échec de l’initialisation du composant', 'error');
        }
    }
    

    buildColumns() {
        const baseColumns = [
            { label: 'Nom du produit', fieldName: 'productName', type: 'text' },
            { label: 'Quantité', fieldName: 'quantity', type: 'number' },
            { label: 'Prix unitaire', fieldName: 'unitPrice', type: 'currency' },
            { label: 'Prix total', fieldName: 'totalPrice', type: 'currency' },
            { label: 'Quantité en Stock', fieldName: 'quantityInStock', type: 'number' },
            {
                label: 'Supprimer',
                type: 'button-icon',
                typeAttributes: {
                    iconName: 'utility:delete',
                    name: 'delete',
                    title: 'Supprimer',
                    variant: 'border-filled',
                    alternativeText: 'Supprimer'
                }
            }
        ];

        const normalizedProfile = this.userProfile?.toLowerCase();
        if (normalizedProfile === 'system administrator') {
            baseColumns.push({
                type: 'button',
                label: 'Voir produit',
                typeAttributes: {
                    label: 'Voir produit',
                    name: 'view',
                    iconName: 'utility:preview',
                    variant: 'brand'
                }
            });
        }

        return baseColumns;
    }

    async loadLineItems() {
        try {
            const rawItems = await getOpportunityLineItems({ opportunityId: this.recordId });
            this.lineItems = rawItems.map(item => ({
                id: item.Id,
                quantity: item.Quantity,
                unitPrice: item.UnitPrice,
                totalPrice: item.TotalPrice,
                quantityInStock: item.Product2?.QuantityInStock__c,
                productName: item.Product2?.Name,
                productId: item.Product2?.Id
            }));
        } catch (error) {
            console.error('Erreur lors du chargement des lignes :', error);
            this.lineItems = [];
        }
    }

    get hasLineItems() {
        return Array.isArray(this.lineItems) && this.lineItems.length > 0;
    }

    handleRowAction(event) {
        const { name } = event.detail.action;
        const row = event.detail.row;

        if (name === 'delete') {
            this.handleDelete(row);
        } else if (name === 'view') {
            this.handleViewProduct(row);
        }
    }

    async handleDelete(row) {
        try {
            await deleteOpportunityLineItem({ lineItemId: row.id });
            this.showToast('Succès', 'Ligne supprimée avec succès', 'success');
            await this.loadLineItems();
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
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
