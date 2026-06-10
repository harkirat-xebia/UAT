import { LightningElement, track } from 'lwc';

const DELAY = 300;

const COLUMNS_DEFINITION = [
  {
    type: 'text',
    fieldName: 'Name',
    label: 'Name',
    typeAttributes: {
      label: { fieldName: 'Name' }
    },
    initialWidth: 150
  },
  {
    type: 'text',
    fieldName: 'InvoiceStatus',
    label: 'Status',
    title: 'InvoiceStatus'
  },
  {
    type: 'currency',
    fieldName: 'TotalAmount',
    label: 'Total Amount'
  },
  {
    type: 'currency',
    fieldName: 'DueAmount',
    label: 'Due Amount'
  },
  {
    type: 'Date',
    fieldName: 'InvoiceDate',
    label: 'Invoice Date'
  },
  {
    type: 'Date',
    fieldName: 'DueDate',
    label: 'Due Date'
  }
];

const GRID_DATA = [
  {
    Name: 'FC One',
    _children: [
      {
        Link: 'http://example.com',
        Name: '123555-A',
        InvoiceStatus: 'Draft',
        TotalAmount: '3150',
        DueAmount: '1500',
        InvoiceDate: '12/03/2022',
        DueDate: '12/03/2022',
        _children: [
          {
            Name: 'line 01',
            TotalAmount: '2000'
          },
          {
            Name: 'line 02',
            TotalAmount: '1000'
          },
          {
            Name: 'line 03',
            TotalAmount: '150'
          }
        ]
      },
      {
        Link: 'http://example.com',
        Name: '123555-B',
        InvoiceStatus: 'Draft',
        TotalAmount: '1800',
        DueAmount: '1500',
        InvoiceDate: '12/03/2022',
        DueDate: '12/03/2022',
        _children: [
          {
            Name: 'line 04',
            TotalAmount: '1000'
          },
          {
            Name: 'line 05',
            TotalAmount: '500'
          },
          {
            Name: 'line 06',
            TotalAmount: '300'
          }
        ]
      }
    ]
  },
  {
    Link: '#',
    Name: 'FC Two',
    _children: [
      {
        Link: 'http://example.com',
        Name: '123523-A',
        InvoiceStatus: 'Draft',
        TotalAmount: '3150',
        DueAmount: '1500',
        InvoiceDate: '12/03/2022',
        DueDate: '12/03/2022',
        _children: [
          {
            Name: 'line 07',
            TotalAmount: '2000'
          },
          {
            Name: 'line 08',
            TotalAmount: '1000'
          },
          {
            Name: 'line 09',
            TotalAmount: '150'
          }
        ]
      },
      {
        Link: 'http://example.com',
        Name: '123523-B',
        InvoiceStatus: 'Draft',
        TotalAmount: '2000',
        DueAmount: '1500',
        InvoiceDate: '12/03/2022',
        DueDate: '12/03/2022',
        _children: [
          {
            Name: 'line 11',
            TotalAmount: '1000'
          },
          {
            Name: 'line 12',
            TotalAmount: '500'
          },
          {
            Name: 'line 13',
            TotalAmount: '500'
          }
        ]
      }
    ]
  }
];

export default class App extends LightningElement {
  @track gridColumns = COLUMNS_DEFINITION;
  @track gridData = GRID_DATA;
  @track expandedRows = [];
  @track selectedRows = [];
  @track filteredRecords = [...this.gridData];

  handleKeyChange(event) {
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    const searchColumn = 'Name';
    var rowIds = [];
    var selectedIds = [];
    if (searchKey) {
      this.delayTimeout = setTimeout(() => {
        this.filteredRecords = this.gridData.filter((item) => {
          var isContains = false;
          for (let i = 0; i < item._children.length; i++) {
            for (let j = 0; j < item._children[i]._children.length; j++) {
              if (JSON.stringify(item._children[i]._children[j]).toLowerCase().includes(searchKey.toLowerCase())) {
                console.log('//NGO 2');
                rowIds.push(item.Name);
                rowIds.push(item._children[i].Name);
                rowIds.push(item._children[i]._children[j].Name);
                selectedIds.push(item._children[i]._children[j].Name);
                isContains = true;
              }
            }
          }
          if (isContains) return isContains;
          for (let i = 0; i < item._children.length; i++) {
            if (JSON.stringify(item._children[i]).toLowerCase().includes(searchKey.toLowerCase())) {
              console.log('//NGO 1');
              rowIds.push(item.Name);
              selectedIds.push(item._children[i].Name);
              isContains = true;
            }
          }
          if (isContains) return isContains;
          if (JSON.stringify(item).toLowerCase().includes(searchKey.toLowerCase())) {
            console.log('//NGO 3');
            selectedIds.push(item.Name);
            isContains = true;
          }
          return isContains;
        });
        console.log('//NGO rows : ' + rowIds);
        this.expandedRows = rowIds;
        this.selectedRows = selectedIds;
      }, DELAY);
    } else {
      this.filteredRecords = this.gridData;
      this.selectedRows = [];
      this.expandedRows = [];
    }
  }
}