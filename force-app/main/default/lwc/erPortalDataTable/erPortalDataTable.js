import { LightningElement, api } from 'lwc';

export default class ErPortalDataTable extends LightningElement {
  @api tableDatas = []; // datas passed by parent
  @api tableStyle; // horizontal ou vertical, si hor --> 1ere col titles, si ver ---> 1ere ligne titles
  @api propertyName; // Name of data table, it's used for two way binding abstraction
  @api displayColumns; // List of columns that have to be displayed (only for vertical tables)
  @api isReadOnly = false; // in order to hide "edit" and "remove" buttons in case of read only
  @api labels = {};
  @api currentRow = 0;
  @api showRadioBtn = false;
  columns = []; // Only for vertical tables

  get isVertical() {
    return this.tableStyle === 'vertical';
  }

  handleSelect(event) {
    this.dispatchCustomEvent(event, 'change');
  }

  editRow(event) {
    this.currentRow = event.target.value - 1;
    this.dispatchCustomEvent(event, 'edit');
  }

  removeRow(event) {
    this.dispatchCustomEvent(event, 'remove');
  }

  dispatchCustomEvent(event, eventName) {
    const changeEvent = new CustomEvent(eventName, {
      detail: { list: this.propertyName, value: event.target.value - 1 }
    });
    this.dispatchEvent(changeEvent);
  }

  get tableDatasDisplay() {
    const showRadioBtn = JSON.parse(this.showRadioBtn); // Convert string to boolean
    const cssHeader = 'erportal-datatable-cell erportal-datatable-header';
    const cssValue = 'erportal-datatable-cell erportal-datatable-value';
    let tableDatasTransformed = [];

    if (this.tableStyle === 'horizontal') {
      // Case for horizontal tables that manage one record only like financial conditions
      this.tableDatas.forEach((row, index) => {
        let cellValues = [];
        cellValues.push({
          cellIndex: 0,
          content: Object.keys(row)[0],
          className: cssHeader + ' erportal-datatable-cell__horizontal'
        });
        cellValues.push({
          cellIndex: 1,
          content: Object.values(row)[0],
          tooltip: Object.values(row)[1],
          className: cssValue + ' erportal-datatable-cell__horizontal'
        });

        tableDatasTransformed.push({ rowIndex: index, cellValues: cellValues });
      });
    } else if (this.tableStyle === 'vertical') {
      // Case for vertical tables that manage multiple records like list of terminals
      let colNames = [];
      let btnClassName = cssValue + ' erportal-datatable-buttons'; // css for buttons edit and delete
      let columnsDisplayed;
      if (this.displayColumns) columnsDisplayed = Object.keys(this.displayColumns);

      this.tableDatas.forEach((row, index) => {
        // Set the column headers first
        if (index === 0) {
          colNames = Object.keys(row);
          let headerInfos = [];
          colNames.forEach((cell, index) => {
            let cssVal = index > 0 ? cssHeader + ' hidden-col-responsive' : cssHeader;
            if (columnsDisplayed && columnsDisplayed.includes(cell)) {
              headerInfos.push({
                cellIndex: index,
                content: this.displayColumns[cell],
                className: cssVal
              });
            } else if (!columnsDisplayed) {
              headerInfos.push({
                cellIndex: index,
                content: cell,
                className: cssVal
              });
            }
          });

          // this.columns.push({rowIndex: index, cellValues: headerInfos});
          tableDatasTransformed.push({
            rowIndex: index,
            cellValues: headerInfos,
            showButtons: false,
            className: cssHeader
          });
        }

        // Then set all the row values
        let cellValues = [];
        colNames.forEach((colName, index) => {
          let cssVal = index > 0 ? cssValue + ' hidden-col-responsive' : cssValue;
          if (!columnsDisplayed || columnsDisplayed.includes(colName))
            cellValues.push({
              cellIndex: index,
              content: row[colName],
              className: cssVal,
              href: row['href'],
              hasLink: row['hasLink']
            });
        });
        let isChecked = this.currentRow === index ? true : false;
        let showEditButtons = (!this.isReadOnly && this.isReadOnly != undefined) || row.isNew ;
        tableDatasTransformed.push({
          rowIndex: index + 1,
          cellValues: cellValues,
          showButtons: showRadioBtn,
          checked: isChecked,
          showEditButtons: showEditButtons,
          hideDelete: row.noDelete,
          className: btnClassName
        });
      });
    }

    return tableDatasTransformed;
  }
}