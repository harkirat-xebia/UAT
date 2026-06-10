<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>User_First_Inactivity_Notification</fullName>
        <description>User First Inactivity Notification</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Core/Notification_First_User_Email_Deactivation</template>
    </alerts>
    <alerts>
        <fullName>User_Second_Inactivity_Notification</fullName>
        <description>User Second Inactivity Notification</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Core/Notification_Second_User_Email_Deactivation</template>
    </alerts>
</Workflow>
