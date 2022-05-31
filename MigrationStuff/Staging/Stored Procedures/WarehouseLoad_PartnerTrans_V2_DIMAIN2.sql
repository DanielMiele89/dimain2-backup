
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 01/02/2016
-- Description: Populate PartnerTrans Table for Relational 
-- Mod: ChrisM 17/06/2020 speeded up one query
-- 
-- Mod: Rory 2020-07-02	V2 Script created from scratch
-- Migration mod: commented out index disable / rebuild
-- *******************************************************************************

create PROCEDURE [Staging].[WarehouseLoad_PartnerTrans_V2_DIMAIN2]
		
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Write entry to JobLog Table
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog_Temp]
		SELECT StoredProcedureName = OBJECT_NAME(@@PROCID)
			 , TableSchemaName = 'Relational'
			 , TableName = 'PartnerTrans'
			 , StartDate = GETDATE()
			 , EndDate = NULL
			 , TableRowCount  = NULL
			 , AppendReload = 'R'


	/*******************************************************************************************************************************************
		2.	Fetch all incentivised transactions for nFI customers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
		SELECT tr.MatchID
			 , tr.FanID
			 , tr.ClubCash
			 , tr.PartnerCommissionRuleID
			 , tr.TypeID
		INTO #Trans
		FROM [SLC_Report].[dbo].[Trans] tr
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[Customer] cu
						WHERE tr.FanID = cu.FanID)

		CREATE CLUSTERED INDEX CIX_MatchID ON #Trans (MatchID)


	/*******************************************************************************************************************************************
		3.	Join incentivised transactions for nFI customers to the Match table to get additional columns
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TransMatch') IS NOT NULL DROP TABLE #TransMatch
		SELECT ma.ID AS MatchID
			 , ma.Amount AS TransactionAmount
			 , ma.TransactionDate
			 , ma.AddedDate
			 , ma.AffiliateCommissionAmount AS CommissionChargable
			 , ma.RetailOutletID
			 , ro.PartnerID
			 , tr.FanID
			 , tr.PartnerCommissionRuleID
			 , COALESCE(tr.ClubCash, 0) AS CashbackEarned
			 , tr.TypeID
			 , ma.Status
			 , ma.RewardStatus
		INTO #TransMatch
		FROM [SLC_Report].[dbo].[Match] ma
		INNER JOIN #Trans tr
			ON ma.ID = tr.MatchID
		INNER JOIN [SLC_Report].[dbo].[RetailOutlet] ro
			ON ma.RetailOutletID = ro.ID
		WHERE ma.Status = 1
		AND RewardStatus IN (0, 1)

		CREATE NONCLUSTERED INDEX IX_PCRID ON #TransMatch (TypeID)


	/*******************************************************************************************************************************************
		4.	Update the CashbackEarned column to display negative values for refunds
	*******************************************************************************************************************************************/

		UPDATE tm
		SET tm.CashbackEarned = tm.CashbackEarned * tt.Multiplier
		FROM #TransMatch tm
		INNER JOIN [SLC_Report].[dbo].[TransactionType] tt
			ON tm.TypeID = tt.ID

		CREATE CLUSTERED INDEX CIX_PCRID ON #TransMatch (PartnerCommissionRuleID)


	/*******************************************************************************************************************************************
		5.	Insert to [Relational].[PartnerTrans]
	*******************************************************************************************************************************************/

		DECLARE @RowCount BIGINT

		--ALTER INDEX [IDX_FID] ON [Relational].[PartnerTrans] DISABLE
		--ALTER INDEX [IDX_IID] ON [Relational].[PartnerTrans] DISABLE
		--ALTER INDEX [IDX_MID] ON [Relational].[PartnerTrans] DISABLE
		--ALTER INDEX [IDX_OID] ON [Relational].[PartnerTrans] DISABLE
		--ALTER INDEX [IDX_PID] ON [Relational].[PartnerTrans] DISABLE

		TRUNCATE TABLE [Relational].[PartnerTrans]
		INSERT INTO [Relational].[PartnerTrans]
		SELECT m.MatchID
			 , m.FanID
			 , m.PartnerID
			 , m.RetailOutletID as OutletID
			 , m.TransactionAmount
			 , CONVERT(DATE, m.TransactionDate)	as TransactionDate
			 , CONVERT(DATE, m.AddedDate) as AddedDate
			 , CONVERT(SMALLMONEY, CashBackEarned) AS CashBackEarned
			 , m.CommissionChargable
			 , pcr.IronOfferID
		FROM #TransMatch m
		INNER JOIN [Relational].[IronOffer_PartnerCommissionRule] pcr
			ON m.PartnerCommissionRuleID = pcr.ID
			AND pcr.TypeID = 1
			AND pcr.Status = 1	--		???

		SET @RowCount = @@ROWCOUNT

		--ALTER INDEX ALL ON [Relational].[PartnerTrans] REBUILD


	/*******************************************************************************************************************************************
		6.	Update entry in JobLog Table with End Date
	*******************************************************************************************************************************************/

		UPDATE [Staging].[JobLog_Temp]
		SET EndDate = GETDATE()
		  , TableRowCount = @RowCount
		WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
		AND TableSchemaName = 'Relational'
		AND TableName = 'PartnerTrans'
		AND EndDate IS NULL


	/*******************************************************************************************************************************************
		7.	Insert entry to JobLog Table
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[JobLog]
		SELECT StoredProcedureName
			 , TableSchemaName
			 , TableName
			 , StartDate
			 , EndDate
			 , TableRowCount
			 , AppendReload
		FROM [Staging].[JobLog_Temp]

		TRUNCATE TABLE [Staging].[JobLog_Temp]


END
