<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>CreateTaskForContractExcludedBUs</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Business_Unit__c</field>
        <value xsi:type="xsd:string">CEN</value>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">This MDT entry should contain the list of BUs should be excluded from the process of task creation when a contract is activated.
The value should have as an entry the BU vale separated with semi-column or All (Ex. CZ;HU or ALL). All for all BUs</value>
    </values>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">CZ;HU;BENELUX</value>
    </values>
    <values>
        <field>Valueforformula__c</field>
        <value xsi:nil="true"/>
    </values>
</CustomMetadata>
