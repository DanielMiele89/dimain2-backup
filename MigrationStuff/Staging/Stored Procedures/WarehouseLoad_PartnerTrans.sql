
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 01/02/2016
-- Description: Populate PartnerTrans Table for Relational 
-- Mod: ChrisM 17/06/2020 speeded up one query
-- *******************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_PartnerTrans]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_PartnerTrans',
	TableSchemaName = 'Relational',
	TableName = 'PartnerTrans',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


/***********************************************
**********Relational PartnerTrans Build*********
***********************************************/
--Build PartnerTrans table. This represents transactions made with our partners.
DECLARE @ChunkSize INT,
	@StartRow BIGINT,
	@FinalRow BIGINT,
	@StagingRow BIGINT,
	@RelationalRow BIGINT

SET @ChunkSize = 10000000
SET @StartRow = 0

/* ChrisM 17/06/2020 crazy - sometimes this runs for over an hour.
SET @FinalRow = (
		SELECT MAX(MatchID)
		FROM SLC_Report.dbo.Match m WITH (NOLOCK)
		INNER JOIN SLC_Report.dbo.Trans t WITH (NOLOCK)
			ON t.MatchID = m.ID
		INNER JOIN Relational.Customer c WITH (NOLOCK) 
			ON t.FanID = c.FanID
		INNER JOIN Relational.Outlet o WITH (NOLOCK)
			ON m.RetailOutletID = o.ID
		INNER JOIN Relational.IronOffer_PartnerCommissionRule pcr
			ON t.PartnerCommissionRuleID = pcr.ID
			AND pcr.TypeID = 1
			AND pcr.Status = 1
		INNER JOIN Relational.IronOffer io
			ON pcr.IronOfferID = io.ID
		LEFT OUTER Join SLC_Report.dbo.TransactionType tt
			ON t.TypeID = tt.ID
		WHERE	m.[Status] = 1 -- Eligible for Cashback
			AND m.rewardstatus IN (0,1) -- Eligible for Cashback
			AND o.ID > 0
		)
*/
-- this alternative runs in a second
SELECT TOP(1) @FinalRow = m.ID
FROM SLC_Report.dbo.Match m 
INNER JOIN SLC_Report.dbo.Trans t 
	ON t.MatchID = m.ID
INNER JOIN Relational.Customer c 
	ON t.FanID = c.FanID
INNER JOIN Relational.Outlet o 
	ON m.RetailOutletID = o.ID
INNER JOIN Relational.IronOffer_PartnerCommissionRule pcr
	ON t.PartnerCommissionRuleID = pcr.ID
	AND pcr.TypeID = 1
	AND pcr.Status = 1
INNER JOIN Relational.IronOffer io
	ON pcr.IronOfferID = io.ID
LEFT OUTER Join SLC_Report.dbo.TransactionType tt
	ON t.TypeID = tt.ID
WHERE	m.[Status] = 1 -- Eligible for Cashback
	AND m.rewardstatus IN (0,1) -- Eligible for Cashback
	AND o.ID > 0
ORDER BY m.ID DESC	


Truncate TABLE Relational.PartnerTrans

SET @StagingRow = ISNULL((SELECT MAX (pt.MatchID) FROM Relational.PartnerTrans pt WITH (NOLOCK)),0)

WHILE @FinalRow > @StagingRow
BEGIN

	INSERT INTO Relational.PartnerTrans
	SELECT	m.ID as MatchID,
		c.FanID as FanID,
		o.PartnerID as PartnerID,
		o.ID as OutletID,
		m.Amount as TransactionAmount,
		CAST(m.TransactionDate AS DATE)	as TransactionDate,
		CAST(m.AddedDate AS DATE) as AddedDate,
		CAST(CASE 
			WHEN t.ClubCash IS null then 0
			ELSE t.ClubCash * tt.Multiplier
		END AS SMALLMONEY) as CashBackEarned,
		(CASE
			WHEN m.[Status] = 1 AND RewardStatus IN (0,1) THEN 1 
			ELSE 0
		END * AffiliateCommissionAmount) as CommissionChargable,
		pcr.IronOfferID
	FROM SLC_Report.dbo.Match m WITH (NOLOCK)
	INNER JOIN SLC_Report.dbo.Trans t WITH (NOLOCK)
		ON t.MatchID = m.ID
	INNER JOIN Relational.Customer c WITH (NOLOCK) 
		ON t.FanID = c.FanID
	INNER JOIN Relational.Outlet o WITH (NOLOCK)
		ON m.RetailOutletID = o.ID
	INNER JOIN Relational.IronOffer_PartnerCommissionRule pcr
		ON t.PartnerCommissionRuleID = pcr.ID
		AND pcr.TypeID = 1
		AND pcr.Status = 1
	INNER JOIN Relational.IronOffer io
		ON pcr.IronOfferID = io.ID
	LEFT OUTER Join SLC_Report.dbo.TransactionType tt
		ON t.TypeID = tt.ID
	WHERE	t.MatchID > @StartRow 
		AND t.MatchID <= @StartRow+@ChunkSize 
		AND m.[status] = 1 -- Eligible for Cashback  
		AND m.rewardstatus in (0,1)-- Eligible for Cashback 
		AND o.ID > 0

SET @StartRow = @StartRow+@Chunksize
SET @StagingRow = ISNULL((SELECT MAX (pt.MatchID) FROM Relational.PartnerTrans pt WITH (NOLOCK)),0)

END



ALTER INDEX ALL ON Relational.PartnerTrans REBUILD
/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_PartnerTrans' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'PartnerTrans' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.PartnerTrans)
WHERE	StoredProcedureName = 'WarehouseLoad_PartnerTrans' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'PartnerTrans'
	AND TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp


END
