import { LightningElement, api, track } from 'lwc';
import { keyCodes } from 'c/utilsPrivate';
import { classSet } from 'c/utils';

const i18n = { collapseBranch: 'Collapse', expandBranch: 'Expand' };

// noinspection JSUnusedGlobalSymbols
export default class cTreeItem extends LightningElement {
  @track _children = [];
  @track _tabindexes = {};
  @track _selected = {};
  @track itemsToAdd = [];
  @track itemsToRemove = [];

  @api isDisabled = false;
  @api isRoot = false;
  @api isExpanded;
  @api isChecked;
  @api selected;
  @api nodeRef;
  @api nodeKey;
  @api itemId;
  @api isLeaf;
  @api label;
  @api href;

  _focusedChild = null;

  @api get childItems() {
    return this._children;
  }

  // noinspection JSUnusedGlobalSymbols
  set childItems(value) {
    this._children = value;
    const childLen = this._children.length;
    for (let i = 0; i < childLen; i++) {
      this.setSelectedAttribute(i, 'false');
    }
  }

  @api get focusedChild() {
    return this._focusedChild;
  }

  get childrenCount() {
    return this._children?.length ?? 0;
  }

  get hasChildren() {
    return this.childrenCount > 0;
  }

  setSelectedAttribute(childNum, value) {
    this._selected[childNum] = value;
  }

  connectedCallback() {
    this.dispatchEvent(
      new CustomEvent('privateregisteritem', {
        composed: true,
        bubbles: true,
        detail: {
          focusCallback: this.makeChildFocusable.bind(this),
          unfocusCallback: this.makeChildUnfocusable.bind(this),
          key: this.nodeKey
        }
      })
    );

    this.addEventListener('keydown', this.handleKeydown.bind(this));
  }

  renderedCallback() {
    if (typeof this.focusedChild === 'number') {
      const child = this.getNthChildItem(this.focusedChild + 1);
      if (child) {
        child.tabIndex = '0';
      }
    }
  }

  get buttonLabel() {
    if (this.nodeRef && this.nodeRef.isExpanded) {
      return i18n.collapseBranch;
    }
    return i18n.expandBranch;
  }

  get showExpanded() {
    if (!this.nodeRef) {
      return false;
    }
    return !this.isDisabled && this.nodeRef.isExpanded;
  }

  get computedButtonClass() {
    return classSet('slds-button slds-button_icon slds-m-right_x-small ')
      .add({
        'slds-hidden': this.isLeaf || this.isDisabled
      })
      .toString();
  }

  get computedIconName() {
    return document.dir === 'rtl' ? 'utility:chevronleft' : 'utility:chevronright';
  }

  get children() {
    return this._children.map((child, idx) => {
      return {
        node: child,
        tabindex: this._tabindexes[idx],
        selected: this._selected[idx]
      };
    });
  }

  handleClick(event) {
    if (!this.isDisabled) {
      // eslint-disable-next-line no-script-url
      if (this.href === 'javascript:void(0)') {
        event.preventDefault();
      }
      let target = 'anchor';
      if (event.target !== undefined) {
        if (event.target.tagName === 'BUTTON' || event.target.tagName === 'C-PRIMITIVE-ICON') {
          target = 'chevron';
        }
      }
      const customEvent = new CustomEvent('privateitemclick', {
        bubbles: true,
        composed: true,
        cancelable: true,
        detail: {
          itemId: this.nodeRef.itemId,
          key: this.nodeKey,
          clickedTag: event.target.tagName,
          target
        }
      });
      this.dispatchEvent(customEvent);
    }
  }

  handleKeydown(event) {
    switch (event.keyCode) {
      case keyCodes.space:
      case keyCodes.enter:
        this.preventDefaultAndStopPropagation(event);
        this.template.querySelector('.slds-tree__item a').click();
        break;
      case keyCodes.up:
      case keyCodes.down:
      case keyCodes.right:
      case keyCodes.left:
      case keyCodes.home:
      case keyCodes.end:
        this.preventDefaultAndStopPropagation(event);
        this.dispatchEvent(
          new CustomEvent('privateitemkeydown', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {
              key: this.nodeKey,
              keyCode: event.keyCode
            }
          })
        );

        break;

      default:
        break;
    }
  }

  getChildNum(childKey) {
    const idx = childKey.lastIndexOf('.');
    const childNum = idx > -1 ? parseInt(childKey.substring(idx + 1), 10) : parseInt(childKey, 10);
    return childNum - 1;
  }

  makeChildFocusable(childKey, shouldFocus, shouldSelect) {
    const child = this.getImmediateChildItem(childKey);
    if (child) {
      if (child.tabIndex !== '0') {
        child.tabIndex = '0';
      }
      if (shouldFocus) {
        child.focus();
      }
      if (shouldSelect) {
        child.ariaSelected = true;
      }
    }
  }

  makeChildUnfocusable() {
    this.ariaSelected = 'false';
    this.removeAttribute('tabindex');
  }

  getImmediateChildItem(key) {
    return this.template.querySelector("c-tree-item[data-key='" + key + "']");
  }

  getNthChildItem(n) {
    return this.template.querySelector('c-tree-item:nth-of-type(' + n + ')');
  }
}