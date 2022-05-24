-- =============================================
-- Author:		Chris Morris
-- Create date: 20180604
-- Description:	Mimics SSIS package WarehouseETLChangeLog
-- Runs in about 00:03:35 second time around
-- =============================================
CREATE PROCEDURE [dbo].[WarehouseETLChangeLog] 
AS

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- check changelog has run
--------------------------------------------------------------------------------
IF NOT EXISTS (
	SELECT 1
	FROM Archive_Light.ChangeLog.RunLog
	WHERE CAST(CompletionTime AS DATE) = CAST(GETDATE() AS DATE)
)
BEGIN
	exec msdb..sp_send_dbmail 
		@profile_name = 'Administrator', 
		@recipients = 'Christopher.Morris@rewardinsight.com;',
		@subject = 'ChangeLog process check FAILED for Staging InsightArchiveData',
		@body='FAILURE',
		@body_format = 'TEXT', 
		@importance = 'HIGH', 
		@exclude_query_output = 1  
	RETURN -1
END



--------------------------------------------------------------------------------
-- Clear Staging InsightArchiveData (with fail)
--------------------------------------------------------------------------------
-- EXEC Staging.InsightArchiveData_Clear
TRUNCATE TABLE Staging.InsightArchiveData;


--------------------------------------------------------------------------------
-- Load Staging InsightArchiveData (with fail)
--------------------------------------------------------------------------------
INSERT INTO Staging.InsightArchiveData (FanID, [Date], TypeID)
SELECT [FanID], [Date], TypeID
FROM (
	-------------------------------------------------------------------------
	--------------Create list of activation dates for deactivators ----------
	-------------------------------------------------------------------------
      SELECT      FANID,
                  Min(Value) as [Date],
                  1 as TypeID

      from Archive_Light.ChangeLog.DataChangeHistory_Datetime as dt
      inner join Archive_Light.ChangeLog.TableColumns as tc
            on dt.TableColumnsID = tc.ID
      inner join slc_report.dbo.Fan as f
            on dt.FanID = f.ID
      Where ColumnName = 'AgreedTCsDate' and 
              not(Value is NULL) and ClubID in (132,138)
            and (f.AgreedTCsDate is null or f.AgreedTCs = 0)
      Group by FanID

      UNION ALL

	-------------------------------------------------------------------------
	-----------------Create list of changes of email address-----------------
	-------------------------------------------------------------------------
      SELECT      a.FanID,
                  Max(a.ChangedDate) as LastChangedDate,
                  a.[TypeID]
      From
      (Select Distinct 
                  n.FanID,
                  n.[Date] as ChangedDate,
                  2 as [TypeID]
      from Archive_Light.Changelog.DataChangeHistory_Nvarchar as n with (nolock)
      inner join SLC_Report.dbo.fan as f
            on    n.fanid = f.id and 
                  n.Value = f.Email -- email address must be different to now
      Where n.TableColumnsID = 2 and
                  Cast(n.[Date] as date) > DateAdd(day,1,Cast(f.AgreedTCsDate as Date)) and
                  len(f.email) > 7 and
                  f.ClubID in (132,138)
      ) as a
      Group By a.FanID,a.[TypeID]

      UNION ALL

	-------------------------------------------------------------------------
	-----------------------Create list of Unsubscribe Dates------------------
	-------------------------------------------------------------------------
	SELECT      b.FanID,
				Max(Cast(Date as date)) as ChangeDate,
				3 as [TypeID]
	--Into #UnSub
	from Archive_Light.ChangeLog.DataChangeHistory_Bit as b
	inner join slc_report.dbo.Fan as f
		  on    b.FanID = f.ID
	where TableColumnsID = 15 and 
				b.Value = 1 and 
				f.ClubID in (132,138) and
				f.AgreedTCs = 1 and
				f.Unsubscribed = 1
	Group By b.FanID
) as Com



--------------------------------------------------------------------------------
-- Load CustomerActivationDate
--------------------------------------------------------------------------------
DECLARE @CustomerActivationDate DATETIME
SELECT @CustomerActivationDate = MAX(AuditDate) FROM MI.CustomerActivationHistory


--------------------------------------------------------------------------------
-- Load CustomerActivationHistory
--------------------------------------------------------------------------------
INSERT INTO [MI].[CustomerActivationHistory] 
	(FanID, ActivationStatusID, ActivatedOffline, StatusDate, IsRBS, AuditDate)

SELECT d.FanID, 1 AS ActivationStatusID, isnull(f.OfflineOnly,0) AS ActivatedOffline, COALESCE(f.AgreedTCsDate,DATEADD(DAY, -1,d.[Date])) StatusDate
	, CAST(CASE WHEN f.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS, d.[Date] AS AuditDate
FROM Archive_Light.ChangeLog.DataChangeHistory_Bit d
INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
WHERE f.ClubID in (132,138) AND d.TableColumnsID = 20 AND D.Value = 1 AND d.[Date] > @CustomerActivationDate

UNION
--customers who have been deactivated
SELECT d.FanID, 3, 0, DATEADD(DAY, -1,d.[Date]), CAST(CASE WHEN f.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS, d.[Date]
FROM Archive_Light.ChangeLog.DataChangeHistory_Int d
INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
WHERE f.ClubID IN (132,138) AND d.TableColumnsID = 12 AND D.Value = 0 AND d.[Date] > @CustomerActivationDate

UNION
--customers who have opted out
SELECT d.FanID, 2, CAST(0 AS BIT) AS ActivatedOffline, DATEADD(DAY, -1,d.[Date]), CAST(CASE WHEN f.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS, d.[Date]
FROM Archive_Light.ChangeLog.DataChangeHistory_Bit d
INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
WHERE f.ClubID IN (132,138) AND d.TableColumnsID = 25 AND D.Value = 1 AND d.[Date] > @CustomerActivationDate


--------------------------------------------------------------------------------
-- Load EmailMobileChangeDate
--------------------------------------------------------------------------------
DECLARE @EmailMobileChangeDate DATETIME
SELECT @EmailMobileChangeDate = DATEADD(HOUR, 12, MAX(CAST(ChangeDate AS DATETIME)))
FROM MI.CustomerEmailMobileChange_Archive


--------------------------------------------------------------------------------
-- Load EmailMobileChangeArchive
--------------------------------------------------------------------------------
INSERT INTO [MI].[CustomerEmailMobileChange_Archive] (FanID, ChangeDate, ChangeType)

SELECT d.FanID, DATEADD(DAY, -1,d.[Date]) AS ChangeDate, CAST('Email' AS VARCHAR(50)) AS ChangeType
FROM Archive_Light.ChangeLog.DataChangeHistory_Nvarchar d
INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
WHERE f.ClubID IN (132,138)
	AND d.TableColumnsID = 2 
	AND d.[Date] > @EmailMobileChangeDate

UNION ALL

SELECT d.FanID, DATEADD(DAY, -1,d.[Date]) AS ChangeDate, CAST('Mobile' AS VARCHAR(50)) AS ChangeType
FROM Archive_Light.ChangeLog.DataChangeHistory_Nvarchar d
INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
WHERE f.ClubID IN (132,138)
	AND d.TableColumnsID = 23 
	AND d.[Date] > @EmailMobileChangeDate


--------------------------------------------------------------------------------
-- Send Success Email
--------------------------------------------------------------------------------
exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Staging InsightArchiveData loaded SUCCESSFULLY',
	@body='SUCCESS',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1





--------------------------------------------------------------------------------
-- Customer Activation History and dependents
--------------------------------------------------------------------------------
--EXEC MI.CustomerActivationHistoryPlusDependents_Refresh
DECLARE @LoadedDate DATETIME
SELECT @LoadedDate = MAX(ChangeDate) FROM MI.CustomerEmailMobileChange

TRUNCATE TABLE MI.CustomerEmailMobileChange

INSERT INTO MI.CustomerEmailMobileChange (FanID, ChangeDate, ChangeType)
SELECT DISTINCT a.FanID, a.ChangeDate, a.ChangeType
FROM MI.CustomerEmailMobileChange_Archive a WITH (NOLOCK)
INNER JOIN MI.CustomerActiveStatus c WITH (NOLOCK) ON a.FanID = C.FanID
WHERE CAST(a.ChangeDate AS DATE) > dateadd(day, 2,c.ActivatedDate)




--------------------------------------------------------------------------------
-- Clear Customer Active Tables
--------------------------------------------------------------------------------
--EXEC MI.CustomerActivationPeriod_Status_Clear
TRUNCATE TABLE Staging.CustomerActivationPeriod
TRUNCATE TABLE MI.CustomerActiveStatus
TRUNCATE TABLE MI.CustomersInactive


--------------------------------------------------------------------------------
-- Load CustomerActivationPeriod
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CAP3') IS NOT NULL DROP TABLE #CAP3;
CREATE TABLE #CAP3 (ID INT, FanID INT, ActivationStart DATETIME, IsRBS BIT)
INSERT INTO #CAP3 (ID, FanID, ActivationStart, IsRBS)
--EXEC MI.CustomerActivationPeriod_Initial_Fetch
SELECT h.ID, h.FanID, h.StatusDate AS ActivationDate, h.IsRBS
FROM MI.CustomerActivationHistory h
WHERE ActivationStatusID = 1;
--ORDER BY FanID, ActivationDate;

INSERT INTO Staging.CustomerActivationPeriod (ID, FanID, ActivationStart)
SELECT ID, FanID, ActivationStart FROM #CAP3


--------------------------------------------------------------------------------
-- Load CustomerActiveStatus
--------------------------------------------------------------------------------
INSERT INTO MI.CustomerActiveStatus (FanID, ActivatedDate, IsRBS)
--EXEC MI.CustomerActiveStatus_Fetch
SELECT h.FanID, MIN(h.StatusDate) AS ActivationDate, h.IsRBS
FROM MI.CustomerActivationHistory h
WHERE ActivationStatusID = 1
GROUP BY h.FanID, h.IsRBS;


--------------------------------------------------------------------------------
-- Load CustomersInactive
--------------------------------------------------------------------------------
INSERT INTO MI.CustomersInactive (FanID, ActivationDate, ActivationStatusID)
--EXEC MI.CustomerActivationPeriod_Inactive_Fetch
SELECT h.FanID, h.StatusDate AS ActivationDate, ActivationStatusID
FROM MI.CustomerActivationHistory h
INNER JOIN Relational.Customer c ON h.FanID = c.FanID
WHERE ActivationStatusID > 1;
--ORDER BY FanID, ActivationDate


--------------------------------------------------------------------------------
-- Check Customer Active Status
--------------------------------------------------------------------------------
EXEC MI.CustomerActivationPeriod_Customer_Update -- 01:33:17


--------------------------------------------------------------------------------
-- Update MI Customer Active Status from Staging
--------------------------------------------------------------------------------
EXEC MI.CustomerActivationPeriod_Staging_Update



RETURN 0