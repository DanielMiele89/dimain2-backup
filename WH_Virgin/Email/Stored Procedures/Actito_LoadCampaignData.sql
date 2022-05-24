
--Creation Date: 2017-07-14; Created By: H Knox; Jira Ticket: RBS-1728 Description: Receive and store Campaign Data 
--Modified Date: 2017-11-02; Modified By: Rajshikha Jain; Jira Ticket: RBS-1728 Description: Receive and store Campaign Data 
--Modified Date: 2020-03-12; Modified By: Edmond Eilerts de Haan; Jira Ticket: INC-467; Description: Remove invalid characters from XML prior to conversion
--Modified Date: 2022-03-02; Modified By: Edmond Eilerts de Haan; Jira Ticket: ???-????; Description: Converted SP for direct insert into programme specific warehouse

/*Uses XML structure:
<?xml version="1.0" encoding="utf-8"?>
<ArrayOfApiGlobalReport xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <apiGlobalReport>
                                <averageTransactionValue>0.0</averageTransactionValue>
                                <campaignId>349226</campaignId>
                                <campaignName>Export sync example test</campaignName>
                                <messageId>181839</messageId>
                                <nbBounces>0</nbBounces>
                                <nbClickers>1</nbClickers>
                                <nbClicks>3</nbClicks>
                                <nbComplaints>0</nbComplaints>
                                <nbConversion>0</nbConversion>
                                <nbDelivered>1</nbDelivered>
                                <nbFiltered>0</nbFiltered>
                                <nbHardBounces>0</nbHardBounces>
                                <nbOpened>1</nbOpened>
                                <nbSelected>1</nbSelected>
                                <nbSent>1</nbSent>
                                <nbShareClicks>0</nbShareClicks>
                                <nbShared>0</nbShared>
                                <nbSharers>0</nbSharers>
                                <nbSnOpened>0</nbSnOpened>
                                <nbSoftBounces>0</nbSoftBounces>
                                <nbTotalOpened>2</nbTotalOpened>
                                <nbTransaction>0</nbTransaction>
                                <nbUnjoined>0</nbUnjoined>
                                <pctBounces>0.0</pctBounces>
                                <pctClickers>100.0</pctClickers>
                                <pctClickersOverOpeners>100.0</pctClickersOverOpeners>
                                <pctComplaints>0.0</pctComplaints>
                                <pctConvertedOverDelivered>0.0</pctConvertedOverDelivered>
                                <pctDelivered>100.0</pctDelivered>
                                <pctFiltered>0.0</pctFiltered>
                                <pctHardBounces>0.0</pctHardBounces>
                                <pctOpened>100.0</pctOpened>
                                <pctSent>100.0</pctSent>
                                <pctSharers>0.0</pctSharers>
                                <pctSoftBounces>0.0</pctSoftBounces>
                                <pctUnjoined>0.0</pctUnjoined>
                                <sendDate>2017-10-11T10:35:13+01:00</sendDate>
                                <valConversion>0.0</valConversion>
                                <valTransaction>0.0</valTransaction>
                </apiGlobalReport>
</ArrayOfApiGlobalReport>
*/
CREATE PROCEDURE [Email].[Actito_LoadCampaignData]
  @CampaignData varchar(max) 
, @ListOfCampaignKeys VARCHAR(8000) = null OUTPUT

--WITH EXECUTE AS OWNER
AS

DECLARE @Now DATETIME = GETDATE()
DECLARE @hdoc INT

IF OBJECT_ID('tempdb..#DownloadCampaignData') IS NOT NULL DROP TABLE #DownloadCampaignData

CREATE TABLE #DownloadCampaignData 
(AverageTransactionValue varchar(10) 
,CampaignKey varchar(10) PRIMARY KEY
,CampaignName Varchar(255)
,MessageId int
,nbBounces int
,nbClickers int
,nbComplaints int
,nbConversion int
,nbDelivered int
,nbFiltered int
,nbHardBounces int
,nbOpened int
,nbSelected int
,nbSent int
,nbShareClicks int
,nbShared int
,nbSharers int
,nbSnOpened int
,nbSoftBounces int
,nbTotalOpened int
,nbTransaction int
,nbUnjoined int
,pctBounces float 
,pctClickers float 
,pctClickersOverOpeners float 
,pctComplaints float 
,pctConvertedOverDelivered float 
,pctDelivered float 
,pctFiltered  float 
,pctHardBounces  float 
,pctOpened float 
,pctSent   float 
,pctSharers  float 
,pctSoftBounces float 
,pctUnjoined  float 
,sendDate DATETIME 
,valConversion float
,valTransaction float
)

--Remove any illegal characters from the XML prior to document preparation
SET @CampaignData = REPLACE(REPLACE(@CampaignData, '£', '#'), '’', '''');

EXEC sp_xml_preparedocument @hdoc OUTPUT, @CampaignData

INSERT INTO #DownloadCampaignData
SELECT *
FROM OPENXML (@hdoc, '/ArrayOfApiGlobalReport/apiGlobalReport')
WITH 
(
averageTransactionValue varchar(10) 'averageTransactionValue'
,campaignId varchar(10) 'campaignId'
,campaignName Varchar(255) 'campaignName'
,messageId int 'messageId'
,nbBounces int 'nbBounces'
,nbClickers int 'nbClickers'
,nbComplaints int 'nbComplaints'
,nbConversion int 'nbConversion'
,nbDelivered int 'nbDelivered'
,nbFiltered int 'nbFiltered'
,nbHardBounces int 'nbHardBounces'
,nbOpened int 'nbOpened'
,nbSelected int 'nbSelected'
,nbSent int 'nbSent'
,nbShareClicks int  'nbShareClicks'
,nbShared int 'nbShared'
,nbSharers int 'nbSharers'
,nbSnOpened int 'nbSnOpened'
,nbSoftBounces int 'nbSoftBounces'
,nbTotalOpened int 'nbTotalOpened'
,nbTransaction int 'nbTransaction'
,nbUnjoined int 'nbUnjoined'
,pctBounces float  'pctBounces'
,pctClickers float  'pctClickers'
,pctClickersOverOpeners float  'pctClickersOverOpeners'
,pctComplaints float  'pctComplaints'
,pctConvertedOverDelivered float  'pctConvertedOverDelivered'
,pctDelivered float  'pctDelivered'
,pctFiltered  float  'pctFiltered'
,pctHardBounces  float  'pctHardBounces'
,pctOpened float  'pctOpened'
,pctSent   float  'pctSent'
,pctSharers  float  'pctSharers'
,pctSoftBounces float  'pctSoftBounces'
,pctUnjoined  float  'pctUnjoined'
,sendDate DATETIME  'sendDate'
,valConversion float 'valConversion'
,valTransaction float 'valTransaction'
)

EXEC sp_xml_removedocument @hdoc

-- if campaign key exist then update else insert the new campaign key

MERGE [Inbound].[EmailCampaign] ec
USING #DownloadCampaignData s 
ON ec.CampaignKey = s.campaignkey
--WHEN MATCHED THEN
--  UPDATE
--  SET ec.EmailsSent = s.nbsent
--	  , ec.EmailsDelivered = nbdelivered
WHEN NOT MATCHED THEN
	INSERT (
	  [ec].[CampaignKey]
	, [ec].[CampaignName]
	, [ec].[EmailKey]
	, [ec].[SendDate]
	, [ec].[Subject] )
	VALUES( CampaignKey --CampaignKey
		 , CampaignName --CampaignName
		 , [s].[MessageId]
		 , sendDate
		 , NULL --Subject
		 );
	
SELECT @ListOfCampaignKeys = ISNULL(STUFF 
((
    SELECT ',' + #DownloadCampaignData.[CampaignKey]
    FROM #DownloadCampaignData 
    WHERE #DownloadCampaignData.[MessageId] = '0'
    FOR XML PATH('')), 1, 1, '') , '')


SELECT @ListOfCampaignKeys

GO
GRANT EXECUTE
    ON OBJECT::[Email].[Actito_LoadCampaignData] TO [crtimport]
    AS [dbo];

