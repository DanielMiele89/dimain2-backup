-- =============================================
-- Author:		JEA
-- Create date: 03/07/2013
-- Description:	Refreshes the Relational.CustomerActivationHistory
-- table and those tables that rely on its content
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationHistoryPlusDependents_Refresh]

AS
BEGIN
	
	SET NOCOUNT ON;

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CustomerActivationPeriod_Initial_Fetch called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

	DECLARE @LoadedDate DATETIME
	SELECT @LoadedDate = MAX(ChangeDate) FROM MI.CustomerEmailMobileChange

	----List of customers whose most recent activation was offline
	--CREATE TABLE #ActivatedOfflineLatest(FanID int not null)

	--INSERT INTO #ActivatedOfflineLatest(FanID)
	--SELECT c.FanID 
	--FROM MI.CustomerActivationHistory c
	--INNER JOIN (SELECT FanID, MAX(StatusDate) AS StatusDate
	--			FROM MI.CustomerActivationHistory u
	--			WHERE u.ActivationStatusID = 1
	--			GROUP BY FanID) h on c.FanID = h.FanID and c.StatusDate = h.StatusDate
	--WHERE c.ActivationStatusID = 1
	--AND c.ActivatedOffline = 1

	--ALTER TABLE #ActivatedOfflineLatest ADD PRIMARY KEY(FanID)

	--INSERT INTO MI.CustomerActivationHistory(FanID, ActivationStatusID, ActivatedOffline, StatusDate, IsRBS,AuditDate)
	----customers who have activated, along with the flag of whether they activated offline
	--SELECT d.FanID, 1, isnull(f.OfflineOnly,0), COALESCE(f.AgreedTCsDate,DATEADD(DAY, -1,d.[Date])), CAST(CASE WHEN f.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS, d.[Date]
	--FROM Archive.ChangeLog.DataChangeHistory_Bit d
	--INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
	--WHERE f.ClubID in (132,138) AND d.TableColumnsID = 20 AND D.Value = 1 AND d.[Date] > @LoadedDate

	--UNION
	----customers who have been deactivated
	--SELECT d.FanID, 3, 0, DATEADD(DAY, -1,d.[Date]), CAST(CASE WHEN f.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS, d.[Date]
	--FROM Archive.ChangeLog.DataChangeHistory_Int d
	--INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
	--WHERE f.ClubID IN (132,138) AND d.TableColumnsID = 12 AND D.Value = 0 AND d.[Date] > @LoadedDate

	--UNION
	----customers who have opted out
	--SELECT d.FanID, 2, CAST(CASE WHEN l.FanID IS NULL THEN 0 ELSE 1 END AS BIT) AS ActivatedOffline, DATEADD(DAY, -1,d.[Date]), CAST(CASE WHEN f.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS, d.[Date]
	--FROM Archive.ChangeLog.DataChangeHistory_Bit d
	--INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
	--LEFT OUTER JOIN #ActivatedOfflineLatest l ON d.FanID = l.FanID
	--WHERE f.ClubID IN (132,138) AND d.TableColumnsID = 25 AND D.Value = 1 AND d.[Date] > @LoadedDate

	TRUNCATE TABLE MI.CustomerEmailMobileChange

	INSERT INTO MI.CustomerEmailMobileChange(FanID, ChangeDate, ChangeType)
	SELECT DISTINCT a.FanID, a.ChangeDate, a.ChangeType
	FROM MI.CustomerEmailMobileChange_Archive a WITH (NOLOCK)
	INNER JOIN MI.CustomerActiveStatus c  WITH (NOLOCK) ON a.FanID = C.FanID
	WHERE CAST(a.ChangeDate AS DATE) > dateadd(day, 2,c.ActivatedDate)


	--EXEC Relational.CINOptOutList_Refresh

	--EXEC MI.CustomerActiveStatus_Refresh

	--EXEC MI.EarningsDaily_Load

	--EXEC MI.CustomerActivationDaily_Load

	--EXEC MI.CustomerActivationPeriod_Refresh

END
