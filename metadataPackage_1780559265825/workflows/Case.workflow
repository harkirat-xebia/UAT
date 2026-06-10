<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>ER_Email_Notifiaction_for_Case_Team</fullName>
        <description>Email Notifiaction for Case Team</description>
        <protected>false</protected>
        <recipients>
            <recipient>Merchant Support</recipient>
            <type>caseTeam</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Customer_Service_Template/ER_Case_Team</template>
    </alerts>
    <alerts>
        <fullName>ER_Medallia_Escalation_Alert</fullName>
        <description>Medallia Escalation Alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Medallia/ER_Medallia_Case_Escalation_Alert</template>
    </alerts>
    <fieldUpdates>
        <fullName>ChangePriorityToHigh</fullName>
        <field>Priority</field>
        <literalValue>High</literalValue>
        <name>Changes the case priority to high.</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUERES01_Escalation_Client_Sales</fullName>
        <description>Change cases ownership if alert Client Sales cases are not treated in 4 days</description>
        <field>OwnerId</field>
        <lookupValue>ERES_Escalation_Client_Sales</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>ERES Escalation Client Sales</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUERES02_Escalation_Merchant_Sales</fullName>
        <description>Change cases ownership if alert Merchant Sales cases are not treated in 4 days</description>
        <field>OwnerId</field>
        <lookupValue>ERES_Escalation_Merchant_Sales</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>ERES Escalation Merchant Sales</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUERES03_Escalation_Customer_Care</fullName>
        <description>Change cases ownership if alert Customer Care cases are not treated in 4 days</description>
        <field>OwnerId</field>
        <lookupValue>ERES_Escalation_Customer_Care</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>ERES Escalation Customer Care</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUERES04_hasBeenEscalated_Status</fullName>
        <field>hasBeenEscalated__c</field>
        <literalValue>1</literalValue>
        <name>Escalated checkbox field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
