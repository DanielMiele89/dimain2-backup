

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 02/12/2014
-- Description: Find Campaign Key,Email Name,Customer Journey Status,Week Number,Number of Emails Delivered,
-- Open Rate,Click Through Rate,Unsubscribed Rate and Load into Staging Table
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0057_WeeklyEmailPerformanceReport_Load_V3]
			
AS
BEGIN
	SET NOCOUNT ON;


/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'SSRS_R0057_WeeklyEmailPerformanceReport_Load_V3',
	TableSchemaName = 'Staging',
	TableName = 'R_0057_DataTableV2',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


DECLARE	@StartDate DATE,
	@EndDate DATE

SET @StartDate = (SELECT DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE))))
SET @EndDate = (SELECT DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE)))


IF OBJECT_ID ('tempdb..#Campaigns') IS NOT NULL DROP TABLE #Campaigns
SELECT	ROW_NUMBER() OVER(ORDER BY SendDate,cls.CampaignKey) as RowNo,
	cls.CampaignKey,
	ec.CampaignName,
	CAST(ec.SendDate as DATE) as SendDate
INTO #Campaigns
FROM Warehouse.Relational.CampaignLionSendIDs cls
INNER JOIN Warehouse.Relational.EmailCampaign ec
	ON cls.CampaignKey = ec.CampaignKey
WHERE CAST(ec.SendDate as DATE) BETWEEN @StartDate AND @EndDate

CREATE CLUSTERED INDEX IDX_CK ON #Campaigns (CampaignKey)


TRUNCATE TABLE Warehouse.Staging.R_0057_MonthEmailReportData

DECLARE	@StartRow TINYINT
SET @StartRow = 1

WHILE @StartRow <= (SELECT MAX(RowNo) FROM #Campaigns)
BEGIN

INSERT INTO Warehouse.Staging.R_0057_MonthEmailReportData
SELECT	ee.FanID,
	cls.ClubID,
	cls.CampaignKey,
	CJS,
	sfd.WeekNumber,
	MAX(CASE WHEN EmailEventCodeID IN (910,1301,605) THEN 1 ELSE 0 END) as SentOK,
	MAX(CASE WHEN EmailEventCodeID IN (1301,605) THEN 1 ELSE 0 END) as Opened,
	MAX(CASE WHEN EmailEventCodeID IN (605) THEN 1 ELSE 0 END) as Clicked,
	MAX(CASE WHEN EmailEventCodeID = 301 THEN 1 ELSE 0 END) as Unsubscribed
FROM Warehouse.Relational.CampaignLionSendIDs cls
INNER JOIN #Campaigns c
	ON cls.CampaignKey = c.CampaignKey
	AND RowNo = @StartRow
INNER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData sfd
	ON cls.CampaignKey = sfd.CampaignKey
INNER JOIN Warehouse.Relational.EmailEvent ee
	ON cls.CampaignKey = ee.CampaignKey
	AND CAST(sfd.[Customer ID] AS INT) = ee.FanID
GROUP BY ee.FanID,cls.ClubID,cls.CampaignKey,CJS, sfd.WeekNumber

SET @StartRow = @StartRow+1

END



IF OBJECT_ID ('Warehouse.Staging.R_0057_DataTableV2') IS NOT NULL DROP TABLE Warehouse.Staging.R_0057_DataTableV2
SELECT	CAST(Warehouse.Staging.fnGetStartOfWeek(c.SendDate)+1 AS DATE) as StartOfWeek,
	CAST(c.SendDate AS DATE) as SendDate,
	me.ClubID,
	c.CampaignName,
	CASE	
		WHEN me.CJS LIKE 'M1%' THEN 'MOT1'
		WHEN me.CJS LIKE 'M2%' THEN 'MOT2'
		WHEN me.CJS LIKE 'M3%' THEN 'MOT3'
		WHEN me.CJS LIKE 'SAV' THEN 'Saver'
		WHEN me.CJS LIKE 'RED' THEN 'Redeemer'
		ELSE '' 
	END as CustomerJourneyStatus,
	WeekNumber,
	SUM(SentOK) as Delivered,
	SUM(Opened) as Opened,
	SUM(Clicked) as Clicked,
	SUM(Unsubscribed) as Unsubscribed
INTO Warehouse.Staging.R_0057_DataTableV2
FROM Warehouse.Staging.R_0057_MonthEmailReportData me
INNER JOIN #Campaigns c
	ON me.CampaignKey = c.CampaignKey
GROUP BY CAST(Warehouse.Staging.fnGetStartOfWeek(c.SendDate)+1 AS DATE),
	CAST(c.SendDate AS DATE),me.ClubID,
	c.CampaignName,
	CASE	
		WHEN me.CJS LIKE 'M1%' THEN 'MOT1'
		WHEN me.CJS LIKE 'M2%' THEN 'MOT2'
		WHEN me.CJS LIKE 'M3%' THEN 'MOT3'
		WHEN me.CJS LIKE 'SAV' THEN 'Saver'
		WHEN me.CJS LIKE 'RED' THEN 'Redeemer'
		ELSE '' 
	END,WeekNumber
ORDER BY StartOfWeek,SendDate, CampaignName,
CustomerJourneyStatus, WeekNumber



TRUNCATE TABLE Warehouse.Staging.R_0057_MonthEmailReportData

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'SSRS_R0057_WeeklyEmailPerformanceReport_Load_V3' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'R_0057_DataTableV2' 
	AND EndDate IS NULL


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (Select COUNT(1) from Staging.R_0057_DataTableV2)
WHERE	StoredProcedureName = 'SSRS_R0057_WeeklyEmailPerformanceReport_Load_V3' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'R_0057_DataTableV2' 
	AND TableRowCount IS NULL
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
INSERT INTO staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp
END