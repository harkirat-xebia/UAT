/**
 * @author: ALK
 * @date: 31/05/2023
 * @desc: erPortalBreadcrumbs
 */

import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex methods
import getBreadcrumbs from '@salesforce/apex/GenericWithoutSharing.getBreadcrumbs';
import getCompanyInfos from '@salesforce/apex/GenericWithoutSharing.getCompanyInfos';

export default class ErPortalBreadcrumbs extends NavigationMixin(LightningElement) {
    @track _crumbs=[];
    @api recId;
    @api token;
    @api mode;
    @api parentId;
    @api scope;
    @track crn;
    @track bu;

  connectedCallback() {
    if (this.token) {
      getCompanyInfos({ crn: this.token })
        .then((data) => {
          console.log('>>> ALK data.accountId : ' + data.accountId);
          this.recId = data.accountId;
          this.getBreadcrumbsDetails();
        })
        .catch((error) => {
          console.log('>>> getCompanyInfos() - error ' + error);
        });
      this.recId = this.token;
      this.getBreadcrumbsDetails();
    } else {
      this.getBreadcrumbsDetails();
    }
  }

  getBreadcrumbsDetails() {
    if (this.mode && this.mode.toLowerCase() === 'new') this.recId = this.parentId;

    //call apex getBreadcrumbs to fill in _crumbs
    getBreadcrumbs({ recId: this.recId })
      .then((data) => {
        console.log('>>> getBreadcrumbs() - this.recId4 ' + this.recId);
        console.log('>>> getBreadcrumbs() - data ' + data);
        let dataJSON = JSON.parse(data);

        this.crn = dataJSON.crn;
        this.bu = dataJSON.bu;

            this._crumbs.push({
                label: 'Home',
                name: 'Home',
                href: 'manage-structure?crn=' + dataJSON.crn + '&id=' + dataJSON.aId,
                index: 1
            });

            if (dataJSON.aName) { // Case acceptor
                this._crumbs.push({
                    label: 'Fin center: ' + dataJSON.fcName,
                    name: dataJSON.fcName,
                    href: 'manage-fc?id=' + dataJSON.fcId + '&parentid=' + dataJSON.aId,
                    index: 2
                });
                this._crumbs.push({
                    label: 'Store: ' + dataJSON.stName,
                    name: dataJSON.stName,
                    href: 'manage-store?id=' + dataJSON.stId + '&parentid=' + dataJSON.fcId,
                    index: 3
                });
                if(this.mode.toLowerCase() === "view" || this.mode.toLowerCase() === "edit") this._crumbs.push({
                    label: 'Terminal: ' + dataJSON.aName,
                    name: dataJSON.aName,
                    href: '#',
                    index: 4
                });
                else if(this.mode.toLowerCase() === "new") this._crumbs.push({
                    label: 'Terminal: ' + dataJSON.aName,
                    name: "Add Acceptor",
                    href: '#',
                    index: 4
                });

            } else if (dataJSON.stName) { // Case store

                this._crumbs.push({
                    label: 'Fin center: ' + dataJSON.fcName,
                    name: dataJSON.fcName,
                    href: 'manage-fc?id=' + dataJSON.fcId + '&parentid=' + dataJSON.aId,
                    index: 2
                });

                if(!this.parentId) this._crumbs.push({
                    label: 'Store: ' + dataJSON.stName,
                    name: dataJSON.stName,
                    href: '#',
                    index: 3
                });

                else if(this.mode.toLowerCase() === "new" && this.parentId) {
                    this._crumbs.push({
                        label: 'Store: ' + dataJSON.stName,
                        name: dataJSON.stName,
                        href: 'manage-store?id=' + dataJSON.stId + '&parentid=' + dataJSON.fcId,
                    index: 3});
                    this._crumbs.push({
                        label: 'Add Terminal',
                        href: '#',
                        index: 4
                    });
                }

            } else if (dataJSON.fcName) { // Case fc
                if(this.mode.toLowerCase() != "new") this._crumbs.push({
                    label: 'Invoicing site: ' +
                    dataJSON.fcName, name: dataJSON.fcName,
                    href: '#',
                    index: 2
                });
                else if(this.mode.toLowerCase() === "new" && this.parentId) {
                    this._crumbs.push({
                        label: 'Invoicing site: ' + dataJSON.fcName,
                        name: dataJSON.fcName,
                        href: 'manage-fc?id=' + dataJSON.fcId + '&parentid=' + dataJSON.aId,
                        index: 2
                    });
                    this._crumbs.push({
                        label: 'Add Store',
                        href: '#',
                        index: 3
                    });
                }
            } else if (dataJSON.home && this.mode.toLowerCase() == 'new'){
                this._crumbs.push({
                    label: 'Add Invoicing Site',
                    href: '#',
                    index: 2
                });
            }

        })
        .catch((error) => {
            console.log('>>> getBreadcrumbs() - error ' + error);
            console.log('>>> getBreadcrumbs() - error2 ' + JSON.stringify(error));
        });
    }

    handleNavigateTo(event){
        console.log('>>> handleNavigateTo() - Start ');
        const href = event.currentTarget.dataset.page;
        console.log('>>> handleNavigateTo() - href ' + href);
        event.preventDefault();
        this.navigateUrl(decodeURIComponent(href));
        console.log('>>> handleNavigateTo() - End ');
    }

    navigateUrl(href){
        console.log('>>> navigateUrl() - Start href: ' + href);
        let pgName = href.substring(0, href.indexOf('?'));
        /*console.log('>>> navigateUrl() - pgName ' + pgName);
        let pgParamsStr = href.substring(href.indexOf('?') + 1);
        console.log('>>> navigateUrl() - pgParamsStr ' + pgParamsStr);
        let pgParams = JSON.parse('{"' + pgParamsStr.substring(0, pgParamsStr.indexOf('=')) + '":"' + pgParamsStr.substring(pgParamsStr.indexOf('=') + 1) + '"}');*/

        // Parse the query parameters into an object
        var currentUrl = new URL(window.location.href);
        var base = currentUrl.origin;
        let url = new URL(href, base);
        let pgParams = Object.fromEntries(url.searchParams.entries());
        pgParams.bu = this.bu;
        pgParams.scope = this.scope;
        //pgParams.id = this.recId;
        //pgParams.parentid = this.parentId;
        if(!pgParams.crn) {
            pgParams.mode = this.mode;
        }

    console.log('>>> navigateUrl() - pgParams ' + JSON.stringify(pgParams));

    this[NavigationMixin.Navigate]({ type: 'comm__namedPage', attributes: { pageName: pgName }, state: pgParams });
    console.log('>>> navigateUrl() - End ');
  }
}