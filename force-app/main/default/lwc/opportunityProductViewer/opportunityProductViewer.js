//author: WERMI ADAMA - Mai 2025
// LWC modules
import { LightningElement, api, track, wire } from 'lwc'; // core LWC features
import { NavigationMixin } from 'lightning/navigation'; // navigation mixin
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // toast notifications
import { refreshApex } from '@salesforce/apex'; // refresh @wire cache

// Custom Labels
import Label_NomProduit        from '@salesforce/label/c.Label_NomProduit';        // “Nom Produit”
import Label_Quantite          from '@salesforce/label/c.Label_Quantite';          // “Quantité”
import Label_PrixUnitaire      from '@salesforce/label/c.Label_PrixUnitaire';      // “Prix Unitaire”
import Label_PrixTotal         from '@salesforce/label/c.Label_PrixTotal';         // “Prix Total”
import Label_QuantiteStock     from '@salesforce/label/c.Label_QuantiteStock';     // “Quantité en Stock”
import Label_Supprimer         from '@salesforce/label/c.Label_Supprimer';         // “Supprimer”
import Label_VoirProduit       from '@salesforce/label/c.Label_VoirProduit';       // “Voir Produit”
import Label_MessageStockError from '@salesforce/label/c.Label_MessageStockError'; // “Stock Insuffisant”
import Label_OpportunityProduits from '@salesforce/label/c.Label_OpportunityProduits'; // “Produits Opportunité”
import Label_ErreurMajStock    from '@salesforce/label/c.Label_ErreurMajStock';    // “Erreur MAJ Stock”
import Label_AucunProduit      from '@salesforce/label/c.Label_AucunProduit';      // “Aucun Produit”

// Apex methods
import getOpportunityLineItems   from '@salesforce/apex/OpportunityLineItemController.getOpportunityLineItems'; // fetches line items
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityLineItemController.deleteOpportunityLineItem'; // deletes a line item
import getCurrentUserProfile     from '@salesforce/apex/UserProfileController.getCurrentUserProfile';         // fetches user profile

export default class OpportunityProductViewer extends NavigationMixin(LightningElement) {
    @api recordId;             // current Opportunity Id
    @track lineItems = [];     // data for the datatable
    wiredResult;               // holds @wire result for refreshApex
    userProfile = '';          // stores current user’s profile
    columns = [];              // datatable column definitions

    // grouped labels for ease of use
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
        this.initProfileAndColumns(); // fetch profile & build columns
    }

    async initProfileAndColumns() {
        try {
            this.userProfile = await getCurrentUserProfile(); // call Apex for profile
            this.columns    = this.buildColumns();            // setup datatable columns
        } catch (error) {
            console.error('Erreur d’initialisation :', error);
            this.showToast('Erreur', 'Échec de l’initialisation', 'error'); // notify user
        }
    }

    // load and process line items via @wire
    @wire(getOpportunityLineItems, { opportunityId: '$recordId' })
    wiredLineItems(result) {
        this.wiredResult = result;              // save for refreshApex
        const { data, error } = result;
        if (data) {
            // map raw items to UI-friendly objects
            this.lineItems = data.map(item => {
                const qtyStock = item.Product2?.QuantityInStock__c ?? 0;
                return {
                    id:              item.Id,
                    productName:     item.Product2?.Name,
                    productId:       item.Product2?.Id,
                    quantity:        item.Quantity,
                    unitPrice:       item.UnitPrice,
                    totalPrice:      item.Quantity * item.UnitPrice,
                    quantityInStock: qtyStock,
                    stockError:      (qtyStock - item.Quantity) < 0
                                      ? 'background-image: repeating-linear-gradient(45deg,#eee,#eee 10px,#ddd 10px,#ddd 20px); color: brown; font-weight: bold;'
                                      : 'color: darkgreen; font-weight: bold;'
                };
            });
        } else if (error) {
            console.error('Erreur de chargement des lignes :', error);
            this.lineItems = []; // clear on error
        }
    }

    buildColumns() {
        // base columns for datatable
        const cols = [
            { label: Label_NomProduit,    fieldName: 'productName',     type: 'text' },    // product name
            { label: Label_Quantite,      fieldName: 'quantity',        type: 'number',    // quantity
              cellAttributes: { style: { fieldName: 'stockError' } } },
            { label: Label_PrixUnitaire,  fieldName: 'unitPrice',       type: 'currency' },// unit price
            { label: Label_PrixTotal,     fieldName: 'totalPrice',      type: 'currency' },// total price
            { label: Label_QuantiteStock, fieldName: 'quantityInStock', type: 'number' },  // stock available
            { label: Label_Supprimer,      type: 'button-icon',                                   // delete button
              typeAttributes: {
                  iconName:       'utility:delete',
                  name:           'delete',
                  title:          Label_Supprimer,
                  alternativeText: Label_Supprimer,
                  variant:        'border-filled'
              }
            }
        ];
        // add "View Product" button for admins
        if (this.userProfile?.toLowerCase() === 'system administrator') {
            cols.push({
                type: 'button',
                label: Label_VoirProduit,
                typeAttributes: {
                    label:    Label_VoirProduit,
                    name:     'view',
                    iconName: 'utility:preview',
                    variant:  'brand'
                }
            });
        }
        return cols;
    }

    get hasLineItems() {
        return Array.isArray(this.lineItems) && this.lineItems.length > 0; // checks for data
    }

    get hasStockError() {
        return this.lineItems.some(item => (item.quantityInStock - item.quantity) < 0); // any negative stock?
    }

    handleRowAction(event) {
        const { name, row } = event.detail.action
            ? { name: event.detail.action.name, row: event.detail.row }
            : {};
        if (name === 'delete') this.handleDelete(row); // delete action
        if (name === 'view')   this.handleViewProduct(row); // view action
    }

    // delete via Apex then refresh wire
    async handleDelete(row) {
        try {
            await deleteOpportunityLineItem({ lineItemId: row.id }); // call Apex
            this.showToast('Succès', 'Ligne supprimée', 'success');   // notify
            await refreshApex(this.wiredResult);                       // refresh data
        } catch (error) {
            this.showToast('Erreur', error.body?.message || 'Erreur inconnue', 'error'); // error toast
        }
    }

    handleViewProduct(row) {
        // navigate to Product2 record page
        if (this.userProfile?.toLowerCase() === 'system administrator') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId:     row.productId,
                    objectApiName:'Product2',
                    actionName:   'view'
                }
            });
        }
    }

    // helper to show toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
