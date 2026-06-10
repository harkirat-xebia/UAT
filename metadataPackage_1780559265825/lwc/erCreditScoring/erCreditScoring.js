import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getERESPublicRegister from '@salesforce/apex/APCZ04_AresByIdController.getERESPublicRegister';
import updateCreditScoring from '@salesforce/apex/APCZ04_AresByIdController.updateCreditScoring';
import updatePublicRegister from '@salesforce/apex/APCZ04_AresByIdController.updatePublicRegister';
import getTableInfo from '@salesforce/apex/APCZ04_AresByIdController.getTableInfo';
import getName from '@salesforce/apex/APCZ04_AresByIdController.getName';
import { reduceErrors } from 'c/utils';

//import labels
import LAB_SF_PublicRegister_Title from '@salesforce/label/c.LAB_SF_PublicRegister_Title';
import LAB_SF_PublicRegister_CheckAll from '@salesforce/label/c.LAB_SF_PublicRegister_CheckAll';
import LAB_SF_PublicRegister_CompanyName from '@salesforce/label/c.LAB_SF_PublicRegister_CompanyName';
import LAB_SF_PublicRegister_LegalName from '@salesforce/label/c.LAB_SF_PublicRegister_LegalName';
import LAB_SF_PublicRegister_DIC from '@salesforce/label/c.LAB_SF_PublicRegister_DIC';
import LAB_SF_PublicRegister_OtherFiscalId from '@salesforce/label/c.LAB_SF_PublicRegister_OtherFiscalId';
import LAB_SF_PublicRegister_LegalForm from '@salesforce/label/c.LAB_SF_PublicRegister_LegalForm';
import LAB_SF_PublicRegister_Street from '@salesforce/label/c.LAB_SF_PublicRegister_Street';
import LAB_SF_PublicRegister_ZipCode from '@salesforce/label/c.LAB_SF_PublicRegister_ZipCode';
import LAB_SF_PublicRegister_City from '@salesforce/label/c.LAB_SF_PublicRegister_City';
import LAB_SF_PublicRegister_Country from '@salesforce/label/c.LAB_SF_PublicRegister_Country';
import LAB_SF_PublicRegister_Phone from '@salesforce/label/c.LAB_SF_PublicRegister_Phone';
import LAB_SF_PublicRegister_Email from '@salesforce/label/c.LAB_SF_PublicRegister_Email';
import LAB_SF_PublicRegister_Website from '@salesforce/label/c.LAB_SF_PublicRegister_Website';
import LAB_SF_PublicRegister_SubjectToVAT from '@salesforce/label/c.LAB_SF_PublicRegister_SubjectToVAT';
import LAB_SF_PublicRegister_NumberOfEmployees from '@salesforce/label/c.LAB_SF_PublicRegister_NumberOfEmployees';
import LAB_SF_PublicRegister_CheckAllNace from '@salesforce/label/c.LAB_SF_PublicRegister_CheckAllNace';
import LAB_SF_PublicRegister_Cancel from '@salesforce/label/c.LAB_SF_PublicRegister_Cancel';
import LAB_SF_PublicRegister_Update from '@salesforce/label/c.LAB_SF_PublicRegister_Update';

export default class ErCreditScoring extends LightningElement {
  @api id;
  @api action;
  @api sid;
  @api row;
  CRN;
  isPubReg = false;
  labels;
  res;
  creditScoring;
  creditLimit;
  legalName;
  legalForm;
  street;
  zipCode;
  city;
  nace1;
  nace2;
  email;
  nbEmployees;
  phone;
  iconName;
  isLoadingInfo = false;

  allChk = false;
  allNaceChk = false;
  legalNameChk = false;
  legalFormChk = false;
  streetChk = false;
  zipCodeChk = false;
  cityChk = false;
  countryChk = false;
  phoneChk = false;
  emailChk = false;
  nbEmployeesChk = false;
  scoringChk = false;
  limitChk = false;

  legalName = false;
  legalForm = false;
  street = false;
  zipCode = false;
  city = false;
  country = false;
  phone = false;
  email = false;
  nbEmployees = false;
  scoring = false;
  limit = false;

  isLoadingCreditScoring;

  labels = {
    LAB_SF_PublicRegister_Update,
    LAB_SF_PublicRegister_Cancel,
    LAB_SF_PublicRegister_Title,
    LAB_SF_PublicRegister_CheckAll,
    LAB_SF_PublicRegister_CompanyName,
    LAB_SF_PublicRegister_LegalName,
    LAB_SF_PublicRegister_DIC,
    LAB_SF_PublicRegister_OtherFiscalId,
    LAB_SF_PublicRegister_LegalForm,
    LAB_SF_PublicRegister_Street,
    LAB_SF_PublicRegister_ZipCode,
    LAB_SF_PublicRegister_City,
    LAB_SF_PublicRegister_Country,
    LAB_SF_PublicRegister_Phone,
    LAB_SF_PublicRegister_Email,
    LAB_SF_PublicRegister_Website,
    LAB_SF_PublicRegister_SubjectToVAT,
    LAB_SF_PublicRegister_NumberOfEmployees,
    LAB_SF_PublicRegister_CheckAllNace
  };

  connectedCallback() {
    if (this.action == 'publicRegister') {
      this.isPubReg = true;
      this.getTableInfo();
    } else {
      this.isPubReg = false;
    }
    this.getInfo();
    this.getName();
  }

  getName() {
    getName({ recordId: this.id })
      .then((result) => {
        this.recordName = result;
      })
      .catch((error) => {
        this.showToast('', 'error');
      });
  }

  getTableInfo() {
    getTableInfo()
      .then((result) => {
        this.tablaInfo = JSON.parse(result);
      })
      .catch((error) => {
        this.showToast('', 'error');
      });
  }

  closeQuickAction() {
    const closeQA = new CustomEvent('close');
    this.dispatchEvent(closeQA);
  }
  refreshView() {
    const refreshView = new CustomEvent('refresh');
    this.dispatchEvent(refreshView);
  }

  getInfo() {
    this.isLoadingInfo = true;
    getERESPublicRegister({ recordId: this.id })
      .then((result) => {
        this.isLoadingInfo = false;
        this.iconName = 'action:approval';
        this.res = JSON.parse(result);

        if (this.res.datosProducto.riesgoComercial.rating.ratingInforma)
          this.creditScoring = JSON.stringify(this.res.datosProducto.riesgoComercial.rating.ratingInforma);
        if (this.res.datosProducto.riesgoComercial.rating.opinionCredito)
          this.creditLimit = JSON.stringify(this.res.datosProducto.riesgoComercial.rating.opinionCredito);
        //call method for Credit Scoring update
        if (!this.isPubReg) {
          this.handleUpdate();
        }

        if (this.isPubReg) {
          if (this.res && this.res.datosProducto && this.res.datosProducto.informacionComercial) {
            if (this.res.datosProducto.informacionComercial.identificacion) {
              if (this.res.datosProducto.informacionComercial.identificacion.denominacionActual)
                this.legalName = JSON.stringify(
                  this.res.datosProducto.informacionComercial.identificacion.denominacionActual
                )
                  .replace('"', '')
                  .replace('"', '');
              if (this.res.datosProducto.informacionComercial.identificacion.email)
                this.email = JSON.stringify(this.res.datosProducto.informacionComercial.identificacion.email)
                  .replace('"', '')
                  .replace('"', '');
              if (this.res.datosProducto.informacionComercial.identificacion.listaTelefonos[0])
                this.phone = JSON.stringify(
                  this.res.datosProducto.informacionComercial.identificacion.listaTelefonos[0]
                )
                  .replace('"', '')
                  .replace('"', '');
            }
            if (this.res.datosProducto.informacionComercial.direcciones.direccionActual) {
              if (this.res.datosProducto.informacionComercial.direcciones.direccionActual.codigoPostal)
                this.zipCode = JSON.stringify(
                  this.res.datosProducto.informacionComercial.direcciones.direccionActual.codigoPostal
                )
                  .replace('"', '')
                  .replace('"', '');
              if (this.res.datosProducto.informacionComercial.direcciones.direccionActual.municipio)
                this.city = JSON.stringify(
                  this.res.datosProducto.informacionComercial.direcciones.direccionActual.municipio
                )
                  .replace('"', '')
                  .replace('"', '');
              if (this.res.datosProducto.informacionComercial.direcciones.direccionActual.campoCodificadoTipoVia) {
                if (
                  this.res.datosProducto.informacionComercial.direcciones.direccionActual.campoCodificadoTipoVia.valor
                )
                  this.streetValue = JSON.stringify(
                    this.res.datosProducto.informacionComercial.direcciones.direccionActual.campoCodificadoTipoVia.valor
                  )
                    .replace('"', '')
                    .replace('"', '');
                if (
                  this.res.datosProducto.informacionComercial.direcciones.direccionActual.campoCodificadoTipoVia
                    .tablaDecodificacion
                )
                  this.streetForm = JSON.stringify(
                    this.res.datosProducto.informacionComercial.direcciones.direccionActual.campoCodificadoTipoVia
                      .tablaDecodificacion
                  )
                    .replace('"', '')
                    .replace('"', '');
              }
            }
            if (
              this.res.datosProducto.informacionComercial.datosGenerales &&
              this.res.datosProducto.informacionComercial.datosGenerales.formaJuridica &&
              this.res.datosProducto.informacionComercial.datosGenerales.formaJuridica
                .campoCodificadoFormaJuridicaAmpliada
            ) {
              if (
                this.res.datosProducto.informacionComercial.datosGenerales.formaJuridica
                  .campoCodificadoFormaJuridicaAmpliada.valor
              )
                this.legalFormValue = JSON.stringify(
                  this.res.datosProducto.informacionComercial.datosGenerales.formaJuridica
                    .campoCodificadoFormaJuridicaAmpliada.valor
                )
                  .replace('"', '')
                  .replace('"', '');
              if (
                this.res.datosProducto.informacionComercial.datosGenerales.formaJuridica
                  .campoCodificadoFormaJuridicaAmpliada.tablaDecodificacion
              )
                this.legalFormName = JSON.stringify(
                  this.res.datosProducto.informacionComercial.datosGenerales.formaJuridica
                    .campoCodificadoFormaJuridicaAmpliada.tablaDecodificacion
                )
                  .replace('"', '')
                  .replace('"', '');
            }
            if (
              this.res.datosProducto.informacionComercial.actividad &&
              this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009
            ) {
              if (this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009.valor)
                this.nace1 = JSON.stringify(
                  this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009.valor
                )
                  .replace('"', '')
                  .replace('"', '');
              if (this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009.tablaDecodificacion)
                this.naceName = JSON.stringify(
                  this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009.tablaDecodificacion
                )
                  .replace('"', '')
                  .replace('"', '');
              if (this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009.valor)
                this.naceValue = JSON.stringify(
                  this.res.datosProducto.informacionComercial.actividad.campoCodificadoCnae2009.valor
                )
                  .replace('"', '')
                  .replace('"', '');
            }
            if (
              this.res.datosProducto.informacionComercial.empleados &&
              this.res.datosProducto.informacionComercial.empleados.numeroTotalEmpleados != undefined
            ) {
              this.nbEmployees = JSON.stringify(
                this.res.datosProducto.informacionComercial.empleados.numeroTotalEmpleados
              )
                .replace('"', '')
                .replace('"', '');
            }
            if (
              this.res.datosProducto.informacionComercial.operacionesComerciales &&
              this.res.datosProducto.informacionComercial.operacionesComerciales.ventas &&
              this.res.datosProducto.informacionComercial.operacionesComerciales.ventas.listaPaisesExporta
            ) {
              this.country = JSON.stringify(
                this.res.datosProducto.informacionComercial.operacionesComerciales.ventas.listaPaisesExporta
              )
                .replace('"', '')
                .replace('"', '');
            }
          }

          if (this.tablaInfo.datosProducto.tablaDeLiterales) {
            if (
              this.tablaInfo.datosProducto.tablaDeLiterales[this.legalFormName] &&
              this.tablaInfo.datosProducto.tablaDeLiterales[this.legalFormName][this.legalFormValue]
            ) {
              this.legalForm = JSON.stringify(
                this.tablaInfo.datosProducto.tablaDeLiterales[this.legalFormName][this.legalFormValue]
              )
                .replace('"', '')
                .replace('"', '');
            }
            if (
              this.tablaInfo.datosProducto.tablaDeLiterales[this.streetForm] &&
              this.tablaInfo.datosProducto.tablaDeLiterales[this.streetForm][this.streetValue]
            ) {
              this.street1 = JSON.stringify(
                this.tablaInfo.datosProducto.tablaDeLiterales[this.streetForm][this.streetValue]
              )
                .replace('"', '')
                .replace('"', '');
            }
            if (
              this.tablaInfo.datosProducto.tablaDeLiterales[this.naceName] &&
              this.tablaInfo.datosProducto.tablaDeLiterales[this.naceName][this.naceValue]
            ) {
              this.nace2 = JSON.stringify(this.tablaInfo.datosProducto.tablaDeLiterales[this.naceName][this.naceValue])
                .replace('"', '')
                .replace('"', '');
            }
          }

          if (
            this.res &&
            this.res.datosProducto &&
            this.res.datosProducto.informacionComercial &&
            this.res.datosProducto.informacionComercial.direcciones.direccionActual
          ) {
            if (
              this.res.datosProducto.informacionComercial.direcciones.direccionActual.nombreVia &&
              this.res.datosProducto.informacionComercial.direcciones.direccionActual.numeroVia
            ) {
              this.street =
                this.street1 +
                ' ' +
                JSON.stringify(this.res.datosProducto.informacionComercial.direcciones.direccionActual.nombreVia)
                  .replace('"', '')
                  .replace('"', '') +
                ' ' +
                JSON.stringify(this.res.datosProducto.informacionComercial.direcciones.direccionActual.numeroVia)
                  .replace('"', '')
                  .replace('"', '');
            }
          }
        }
      })
      .catch((error) => {
        this.isLoadingInfo = false;
        this.iconName = 'action:close';
        var message = 'No Company registration number found!';
        this.showToast(message, 'error');
        this.closeQuickAction();
      });
  }

  handleCheckbox(event) {
    if (event.target.name == 'allChk') {
      this.allChk = !this.allChk;
      if (this.allChk) {
        this.legalNameChk = true;
        this.legalFormChk = true;
        this.streetChk = true;
        this.zipCodeChk = true;
        this.cityChk = true;
        this.countryChk = true;
        this.phoneChk = true;
        this.emailChk = true;
        this.nbEmployeesChk = true;
      } else {
        this.legalNameChk = false;
        this.legalFormChk = false;
        this.streetChk = false;
        this.zipCodeChk = false;
        this.cityChk = false;
        this.countryChk = false;
        this.phoneChk = false;
        this.emailChk = false;
        this.nbEmployeesChk = false;
      }
    }
    if (event.target.name == 'allNaceChk') {
      this.allNaceChk = !this.allNaceChk;
      if (this.allNaceChk) {
        this.naceChk = true;
      } else {
        this.naceChk = false;
      }
    }
    if (event.target.name == 'naceChk') {
      this.naceChk = !this.naceChk;
    }
    if (event.target.name == 'legalNameChk') {
      this.legalNameChk = !this.legalNameChk;
    }
    if (event.target.name == 'legalFormChk') {
      this.legalFormChk = !this.legalFormChk;
    }
    if (event.target.name == 'streetChk') {
      this.streetChk = !this.streetChk;
    }
    if (event.target.name == 'zipCodeChk') {
      this.zipCodeChk = !this.zipCodeChk;
    }
    if (event.target.name == 'cityChk') {
      this.cityChk = !this.cityChk;
    }
    if (event.target.name == 'countryChk') {
      this.countryChk = !this.countryChk;
    }
    if (event.target.name == 'phoneChk') {
      this.phoneChk = !this.phoneChk;
    }
    if (event.target.name == 'emailChk') {
      this.emailChk = !this.emailChk;
    }
    if (event.target.name == 'nbEmployeesChk') {
      this.nbEmployeesChk = !this.nbEmployeesChk;
    }
    if (event.target.name == 'creditChk') {
      this.creditChk = !this.creditChk;
    }
  }

  handleChange(event) {
    switch (event.target.name) {
      case 'legalName':
        this.legalName = event.target.value;
        break;
      case 'legalForm':
        this.legalForm = event.target.value;
        break;
      case 'street':
        this.street = event.target.value;
        break;
      case 'zipCode':
        this.zipCode = event.target.value;
        break;
      case 'city':
        this.city = event.target.value;
        break;
      case 'country':
        this.country = event.target.value;
        break;
      case 'phone':
        this.phone = event.target.value;
        break;
      case 'email':
        this.email = event.target.value;
        break;
      case 'nbEmployees':
        this.nbEmployees = event.target.value;
        break;
      case 'creditScoring':
        this.creditScoring = event.target.value;
        break;
      case 'creditLimit':
        this.creditLimit = event.target.value;
        break;
    }
  }

  handleUpdate() {
    if (this.isPubReg) {
      let fieldsToUpdate = {};
      if (this.legalNameChk && this.legalName) {
        fieldsToUpdate['legalName'] = this.legalName;
      }
      if (this.legalFormChk && this.legalForm) {
        fieldsToUpdate['legalForm'] = this.legalForm;
      }
      if (this.streetChk && this.street) {
        fieldsToUpdate['street'] = this.street;
      }
      if (this.zipCodeChk && this.zipCode) {
        fieldsToUpdate['zipCode'] = this.zipCode;
      }
      if (this.cityChk && this.city) {
        fieldsToUpdate['city'] = this.city;
      }
      if (this.countryChk && this.country) {
        fieldsToUpdate['country'] = this.country;
      }
      if (this.phoneChk && this.phone) {
        fieldsToUpdate['phone'] = this.phone;
      }
      if (this.emailChk && this.email) {
        fieldsToUpdate['email'] = this.email;
      }
      if (this.nbEmployeesChk && this.nbEmployees) {
        fieldsToUpdate['nbEmployees'] = this.nbEmployees;
      }
      if (this.naceChk) {
        fieldsToUpdate['naceChk'] = this.nace1 + ' ' + this.nace2;
      }
      if (this.creditChk) {
        if (this.creditLimit == undefined) {
          fieldsToUpdate['limit'] = '';
        } else {
          fieldsToUpdate['limit'] = this.creditLimit;
        }
        if (this.creditScoring == undefined) {
          fieldsToUpdate['scoring'] = '';
        } else {
          fieldsToUpdate['scoring'] = this.creditScoring;
        }
      }
      updatePublicRegister({
        fieldsToUpdate: fieldsToUpdate,
        recordId: this.id
      })
        .then((result) => {
          this.closeQuickAction();
          var message = this.recordName + ' is updated!';
          this.showToast(message, 'success');
          this.refreshView();
        })
        .catch((error) => {
          this.showToast(JSON.stringify(reduceErrors(error)), 'error');
        });
    } else {
      let fieldsToUpdate = {};
      fieldsToUpdate['scoring'] = this.creditScoring;
      fieldsToUpdate['limit'] = this.creditLimit;

      if (this.creditLimit == undefined) {
        fieldsToUpdate['limit'] = '';
      }
      if (this.creditScoring == undefined) {
        fieldsToUpdate['scoring'] = '';
      }

      this.isLoadingCreditScoring = true;
      updateCreditScoring({ fieldsToUpdate: fieldsToUpdate, recordId: this.id })
        .then((result) => {
          var message = this.recordName + ' is updated!';
          this.showToast(message, 'success');
          this.closeQuickAction();
          this.refreshView();
        })
        .catch((error) => {
          this.isLoadingCreditScoring = false;

          this.showToast(JSON.stringify(reduceErrors(error)), 'error');
        });
    }
  }

  handleCancel() {
    this.closeQuickAction();
  }

  showToast(message, variant) {
    const event = new ShowToastEvent({
      title: variant,
      message: message,
      variant: variant,
      mode: 'dismissible'
    });
    this.dispatchEvent(event);
  }
}