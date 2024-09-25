<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <custom>true</custom>
    <description>Current Settings
- Assigned App: OHRS 2.0
- Account (Tab Vis, Record Type Assignment,  Page Layout Assignment, Lightning Page Assignments)- Dashboards - Tab Vis- EHR Immun - Tab Vis
- Home
- Reports
- Returns to Work: Tab Vis
- Sub Immun: Tab Vis</description>
    <flowAccesses>
        <enabled>false</enabled>
        <flow>NCPS_Action_Question_Responses</flow>
    </flowAccesses>
    <flowAccesses>
        <enabled>false</enabled>
        <flow>NCPS_After_Action_Updated</flow>
    </flowAccesses>
    <flowAccesses>
        <enabled>false</enabled>
        <flow>NCPS_Before_Response_Create</flow>
    </flowAccesses>
    <flowAccesses>
        <enabled>false</enabled>
        <flow>OHRS_2_0_Immunization_Flow</flow>
    </flowAccesses>
    <loginFlows>
        <flow>Login_User_Acceptance</flow>
        <flowType>UI</flowType>
        <friendlyName>Login Flow for OHRSBaseline</friendlyName>
        <uiLoginFlowType>VisualWorkflow</uiLoginFlowType>
        <useLightningRuntime>true</useLightningRuntime>
    </loginFlows>
    <userLicense>Salesforce</userLicense>
</Profile>