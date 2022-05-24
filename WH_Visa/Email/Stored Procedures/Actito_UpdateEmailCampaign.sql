
--Creation Date: 2017-07-14; Created By: H Knox; Jira Ticket: RBS-1728 Description: Get list of campaignIDs that do not have an EmailKey
--Modified Date: 2017-11-02; Modified By: Rajshikha Jain; Jira Ticket: RBS-1728 Description: Get Emalkeys for the campaignIDs that do not have an EmailKey
--Modified Date: 2020-03-12; Modified By: Edmond Eilerts de Haan; Jira Ticket: INC-467; Description: Remove invalid characters from XML prior to conversion
--Modified Date: 2022-03-02; Modified By: Edmond Eilerts de Haan; Jira Ticket: ???-????; Description: Converted SP for direct insert into programme specific warehouse

CREATE PROCEDURE [Email].[Actito_UpdateEmailCampaign]
@CampaignDetails varchar(max) 

AS
BEGIN 

DECLARE @hdoc int 

If Object_ID('tempdb..#CampaignDataUpdate') IS NOT NULL DROP TABLE #CampaignDataUpdate
CREATE TABLE #CampaignDataUpdate 
	( analytics bit
	,deliverySpeed int
	,emaildedupflg bit
	,format varchar(128)
	,Campaignid nvarchar(10)
	,lifeStatus varchar(128)
	,mailinglistId int 
	,messageId int
	,name varchar(255)
	,notification bit
	,postClickTracking bit
	,sendDate datetime
	,status varchar(128)
	,strategy varchar(128)
	,target varchar(128)
	,urlEndCampaign varchar(510)
	,valid varchar(128) )


--Remove any illegal characters from the XML prior to document preparation
SET @CampaignDetails = REPLACE(REPLACE(@CampaignDetails, '£', '#'), '’', '''');

EXEC sp_xml_preparedocument @hdoc OUTPUT, @CampaignDetails

INSERT INTO #CampaignDataUpdate 
SELECT analytics 
	,deliverySpeed 
	,emaildedupflg 
	,format 
	,id 
	,lifeStatus 
	,mailinglistId 
	,messageId 
	,name 
	,notification 
	,postClickTracking 
	,sendDate 
	,status 
	,strategy 
	,target 
	,urlEndCampaign 
	,valid 
FROM OPENXML (@hdoc, '/ArrayOfResponseCampaign/responseCampaign')
WITH 
(
	analytics bit 'analytics'
	,deliverySpeed int 'deliverySpeed'
	,emaildedupflg bit 'emaildedupflg'
	,format varchar(128) 'format'
	,id int 'id'
	,lifeStatus varchar(128) 'lifeStatus'
	,mailinglistId int  'mailinglistId'
	,messageId nvarchar(10) 'messageId'
	,name varchar(255) 'name'
	,notification bit 'notification'
	,postClickTracking bit 'postClickTracking'
	,sendDate datetime 'sendDate'
	,status varchar(128) 'status'
	,strategy varchar(128) 'strategy'
	,target varchar(128) 'target'
	,urlEndCampaign varchar(510) 'urlEndCampaign'
	,valid varchar(128) 'valid'
)

UPDATE e
SET e.EmailKey = CAST(c.messageId AS nvarchar)
FROM [Inbound].[EmailCampaign] e
INNER JOIN #CampaignDataUpdate c
ON e.CampaignKey = CAST(c.Campaignid AS nvarchar)
WHERE e.EmailKey = '0'


END


GO
GRANT EXECUTE
    ON OBJECT::[Email].[Actito_UpdateEmailCampaign] TO [crtimport]
    AS [New_DataOps];

