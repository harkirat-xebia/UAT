<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>ERES_Contract_Amendement_notification</fullName>
        <description>ERES Contract Amendement notification</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Spain/ERES_Notification_for_Contract_Amendement</template>
    </alerts>
    <alerts>
        <fullName>ER_Opportunity_Reject_Approval_Alert</fullName>
        <description>Opportunity Reject Approval Alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Quote_Approval_Templates/Quote_Rejected</template>
    </alerts>
    <alerts>
        <fullName>ER_Opportunity_Success_Approval_Alert</fullName>
        <description>Opportunity Success Approval Alert</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Quote_Approval_Templates/Quote_Approved</template>
    </alerts>
    <alerts>
        <fullName>L2W_Opportunities_Email_Alert</fullName>
        <description>L2W Opportunities - Email Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>SME_L2W_Partners_Channel</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>L2W_opportunity_Notification/Opportunity_lead2win</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approval_date</fullName>
        <field>Approval_Date__c</field>
        <formula>LastModifiedDate</formula>
        <name>Approval date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>ER_Opportunity_Approval_Success</fullName>
        <field>ER_Approved__c</field>
        <literalValue>1</literalValue>
        <name>Opportunity Approval Success</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUER09_Account_Status_Client</fullName>
        <field>ER_Status__c</field>
        <literalValue>Active</literalValue>
        <name>FUER09_Account_Status_Client</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUER10_Account_Status_Merchant</fullName>
        <field>ER_Status__c</field>
        <literalValue>Active</literalValue>
        <name>FUER10_Account_Status_Merchant</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Need_Approval</fullName>
        <field>ER_NeedApproval__c</field>
        <literalValue>0</literalValue>
        <name>Need Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Reject_Approval_Status</fullName>
        <field>Finance_Approval_Status__c</field>
        <literalValue>Declined</literalValue>
        <name>Reject Approval Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Reset_Max_Discount</fullName>
        <field>Max_Discount__c</field>
        <name>Reset Max Discount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Finance_Approval</fullName>
        <description>Set Need Financial Approver Value to false.</description>
        <field>ER_Need_Financial_Approval_2__c</field>
        <literalValue>0</literalValue>
        <name>Set Finance Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Approved</fullName>
        <field>ER_Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Set Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Declined</fullName>
        <field>ER_Approval_Status__c</field>
        <literalValue>Declined</literalValue>
        <name>Set Status to Declined</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Approval_Status</fullName>
        <field>Finance_Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Update Approval Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
