/******************************************************************************
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the PartnerTrans first in the Staging and then Relational schema of 
		the Warehouse database
Notes:	Amended to include TransactionWeekStartingCampaign in PartnerTrans which is a week starting 
		field based on Thursday being day one.

------------------------------------------------------------------------------
Modification History

	10/09/2014 - SC - Updated the Indexing to diasble and rebuild and added indexes to the Staging.PartnerTransTable
	03/11/2014 - SB - Updated to correctly mark as above base non-core partners
	25/11/2014 - SB - Updated to deal with CardHolderPresentData extending to varchar(2)
	27/06/2016 - SB - Version created to add new rows rather than rebuild each time

Jason Shipp 15/05/2019
	- Added load of RBS direct debit transactions into Staging.PartnerTrans
	- Updated logic linking OINs to PartnerIDs: Use Warehouse.Relational.DirectDebitOriginator table to link OINs to DirectDebitOriginatorIDs
	- Added TEMPORARY join alternative between Match and PartnerCommissionRule tables on PartnerID for RBS direct debit transactions
	=> This is an interim solution to allow RBS direct debit transactions to flow into BI.SchemeTrans. Permanent solution (feeding PartnerCommissionRuleID into the Match table) will be implemented later by IT

Rory 27/05/2019
	- Extra columns are needed from the Match table for updating fields in Staging.PartnerTrans. A temp table #Match containing relevant rows is used to avoid having to join back the entire Match tale   

Jason Shipp 11/07/2019
	- Refined the link between Match and PartnerCommissionRule tables by additionally linking by IronOfferID via the SLC_Report.dbo.DirectDebitOfferOINs table
	- This still requires: 
		- The SLC_Report.dbo.DirectDebitOfferOINs table to contain unique OINs (Ie. Different Iron Offers can't use the same OIN)
		- The SLC_Report.dbo.PartnerCommissionRule table to contain one entry per DD IronOfferID with a TypeID of 2

Jason Shipp 08/11/2019
	- Fixed logic calculating the CommissionChargable (Investment) for MFDDs, so it doesn't rely on the AffiliateCommissionAmount which is pulled through as NULL from Match

Jason Shipp 11/12/2019
	- Commented out refresh of APW.DirectLoad_OutletOinToPartnerID table, as refresh is done in SchemeTrans incremental load. Refreshing twice has been causing blockages

Jason Shipp 01/04/2020
	- Added condition on join to Warehouse.APW.DirectLoad_OutletOinToPartnerID table to additionally match on PartnerCommissionRuleID for MFDDs (where a PartnerCommissionRuleID exists)
	- To handle Sky, which has multiple Iron Offers on the same DirectDebitOriginatorID


******************************************************************************/

CREATE PROCEDURE [WHB].[IronOfferPartnerTrans_PartnerTrans_V2_Append_DIMAIN]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

	BEGIN TRY

		/*--------------------------------------------------------------------------------------------------
		-----------------------------Write entry to JobLog Table--------------------------------------------
		----------------------------------------------------------------------------------------------------*/
		
		Insert into staging.JobLog_Temp
		Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'PartnerTrans',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	
		/*--------------------------------------------------------------------------*/
		/*--------------------New Staging.PartnerTrans Primary Key------------------*/
		/*--------------------------------------------------------------------------*/

		/*--------------------------------------------------------------------------*/
		/*--------------Extract Data from SLC_Report - Start - PartnerTrans---------*/
		/*--------------------------------------------------------------------------*/

		-- Refresh RetailOutletID/OIN - PartnerID linking table --Jason Shipp 05/03/2019. Update 11/12/2019: Commented out, as refresh is done in SchemeTrans incremental load

		--TRUNCATE TABLE APW.DirectLoad_OutletOinToPartnerID;

		--INSERT INTO APW.DirectLoad_OutletOinToPartnerID (
		--	OutletID
		--	, PartnerID
		--	, Channel
		--	, OIN
		--	, IronOfferID
		--	, DirectDebitOriginatorID
		--	, StartDate
		--	, EndDate
		--	, DDInvestmentProportionOfCashback
		--	, PartnerCommissionRuleID
		--)
		--SELECT -- MFDD
		--	NULL AS OutletID
		--	, oin.PartnerID
		--	, 1 AS Channel
		--	, oin.OIN
		--	, ddo.IronOfferID
		--	, o.ID AS DirectDebitOriginatorID
		--	, oin.StartDate
		--	, oin.EndDate
		--	, pd.[Override] AS DDInvestmentProportionOfCashback
		--	, pcr.ID AS PartnerCommissionRuleID
		--FROM Warehouse.Relational.DirectDebit_MFDD_IncentivisedOINs oin
		--INNER JOIN Warehouse.Relational.DirectDebitOriginator o
		--	ON oin.OIN = o.OIN
		--INNER JOIN SLC_Report.dbo.DirectDebitOfferOINs ddo
		--	ON oin.OIN = ddo.OIN
		--LEFT JOIN SLC_Report.dbo.PartnerCommissionRule pcr
		--	ON ddo.IronOfferID = pcr.RequiredIronOfferID
		--	AND pcr.TypeID = 2
		--	AND pcr.DeletionDate IS NULL
		--LEFT JOIN Warehouse.Relational.nFI_Partner_Deals pd -- Populated from this spreadsheet owned by Finance: S:\Finance\Commercial Terms - PublisherRetailer\Commercial Terms - Publisher_Retailer2.xlsx
		--	ON oin.PartnerID = pd.PartnerID
		--	AND (pd.EndDate >= oin.StartDate OR pd.EndDate IS NULL)
		--	AND (pd.StartDate <= oin.EndDate OR oin.EndDate IS NULL)
		--	AND pd.ClubID = 132
	
		--UNION
	
		--SELECT -- CLO
		--	ro.OutletID
		--	, ro.PartnerID
		--	, CASE ro.Channel 
		--		WHEN 1 THEN 1 -- 1 = Online. Otherwise, offline
		--		WHEN 0 THEN 0
		--		WHEN 2 THEN 0
		--		ELSE NULL 
		--	END AS Channel
		--	, NULL AS OIN
		--	, NULL AS IronOfferID
		--	, NULL AS DirectDebitOriginatorID
		--	, NULL AS StartDate
		--	, NULL AS EndDate
		--	, NULL AS DDInvestmentProportionOfCashback
		--	, NULL AS PartnerCommissionRuleID
		--FROM Warehouse.APW.DirectLoad_RetailOutlet ro; -- This is populated via: WHB.IronOfferPartnerTrans_Outlet_V1_5 => APW.DirectLoad_Outlets_Fetch => APW Build SSIS package data flow
	
		--Build PartnerTrans table. This represents transactions made with our partners.
	
		IF OBJECT_ID('tempdb..#SLC_Trans') IS NOT NULL DROP TABLE #SLC_Trans
		SELECT	TOP 7500000
				*
		INTO #SLC_Trans
		FROM [SLC_Report].[dbo].[Trans]
		ORDER BY ID DESC

		CREATE CLUSTERED INDEX CIX_MatchID ON #SLC_Trans (MatchID)
		CREATE NONCLUSTERED INDEX IX_PanID ON #SLC_Trans (PanID)

		IF OBJECT_ID('tempdb..#SLC_Match') IS NOT NULL DROP TABLE #SLC_Match
		SELECT	*
		INTO #SLC_Match
		FROM [SLC_Report].[dbo].[Match] ma
		WHERE EXISTS (	SELECT 1
						FROM #SLC_Trans tr
						WHERE ma.ID = tr.MatchID)

		CREATE CLUSTERED INDEX CIX_MatchID ON #SLC_Match (ID)

		IF OBJECT_ID('tempdb..#SLC_Pan') IS NOT NULL DROP TABLE #SLC_Pan
		SELECT	*
		INTO #SLC_Pan
		FROM [SLC_Report].[dbo].[Pan] pa
		WHERE EXISTS (	SELECT 1
						FROM #SLC_Trans tr
						WHERE pa.ID = tr.PanID)

		CREATE CLUSTERED INDEX CIX_PanID ON #SLC_Pan (ID)

		

		TRUNCATE TABLE [Staging].[PartnerTrans];
		INSERT INTO [Staging].[PartnerTrans]
		SELECT m.ID AS MatchID
			 , c.FanID
			 , CONVERT(DATE, m.TransactionDate) AS TransactionDate
			 , CONVERT(DATE, m.AddedDate) AS AddedDate
			 , m.RetailOutletID AS OutletID
			 , m.Amount AS TransactionAmount
			 , m.[Status]
			 , m.PartnerCommissionRuleID AS PartnerCommissionRuleID
			 , m.rewardstatus AS rewardstatus
			 , m.AffiliateCommissionAmount AS AffiliateCommissionAmount
			 , CONVERT(INT, NULL) AS PartnerID
			 , CONVERT(DATE, NULL) AS TransactionWeekStarting
			 , CONVERT(TINYINT, NULL) AS TransactionMonth
			 , CONVERT(SMALLINT, NULL) AS TransactionYear
			 , CONVERT(DATE, NULL) AS TransactionWeekStartingCampaign	--new field to hold Thursday equivalent of TransactionWeekStarting
			 , CONVERT(DATE, NULL) AS AddedWeekStarting
			 , CONVERT(TINYINT, NULL) AS AddedMonth
			 , CONVERT(SMALLINT, NULL) AS AddedYear
			 , CONVERT(BIT, NULL) AS ExtremeValueFlag
	 		 , CONVERT(BIT, NULL) AS IsOnline
	 		 , LEFT(COALESCE(m.CardHolderPresentData, MCHP.CardholderPresentData), 1) AS CardHolderPresentData
			 , CONVERT(BIT, NULL) AS EligibleForCashBack
			 , CONVERT(MONEY, NULL) AS CommissionChargable
			 , CONVERT(MONEY, NULL) AS CashbackEarned
			 , CONVERT(INT, NULL) AS IronOfferID
			 , CONVERT(INT, t.ActivationDays) AS ActivationDays
			 , CONVERT(INT, NULL) AS AboveBase
		FROM #SLC_Match m
		INNER JOIN #SLC_Pan p
			ON p.ID = m.PanID
			AND p.AffiliateID = 1  --Affiliate ID = 1 means this a scheme run by Reward (rather than e.g. Quidco)
		INNER JOIN [Relational].[Customer] c
			ON p.CompositeID = c.CompositeID
		INNER JOIN #SLC_Trans t
			ON t.MatchID = m.ID 
			AND c.FanID = t.FanID
		LEFT JOIN [Staging].[MatchCardHolderPresent] MCHP
			ON t.MatchID = MCHP.MatchID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Relational].[PartnerTrans] pt
							WHERE m.ID = pt.MatchID)
		AND m.VectorID <> 40;  -- Jason 15/05/2019
		
		INSERT INTO [Staging].[PartnerTrans]
		SELECT m.ID AS MatchID
			 , c.FanID
			 , CONVERT(DATE, m.TransactionDate) AS TransactionDate
			 , CONVERT(DATE, m.AddedDate) AS AddedDate
			 , m.RetailOutletID AS OutletID
			 , m.Amount AS TransactionAmount
			 , m.[Status]
			 , m.PartnerCommissionRuleID AS PartnerCommissionRuleID
			 , m.RewardStatus
			 , m.AffiliateCommissionAmount AS AffiliateCommissionAmount
			 , CONVERT(INT, NULL) AS PartnerID
			 , CONVERT(DATE, NULL) AS TransactionWeekStarting
			 , CONVERT(TINYINT, NULL) AS TransactionMonth
			 , CONVERT(SMALLINT, NULL) AS TransactionYear
			 , CONVERT(DATE, NULL) AS TransactionWeekStartingCampaign	--new field to hold Thursday equivalent of TransactionWeekStarting
			 , CONVERT(DATE, NULL) AS AddedWeekStarting
			 , CONVERT(TINYINT, NULL) AS AddedMonth
			 , CONVERT(SMALLINT, NULL) AS AddedYear
			 , CONVERT(BIT, NULL) AS ExtremeValueFlag
	 		 , CONVERT(BIT, NULL) AS IsOnline
	 		 , LEFT(COALESCE(m.CardHolderPresentData, MCHP.CardholderPresentData), 1) AS CardHolderPresentData
			 , CONVERT(BIT, NULL) AS EligibleForCashBack
			 , (ISNULL(t.ClubCash * tt.Multiplier,0)  + (ISNULL(t.ClubCash * tt.Multiplier,0) * o.DDInvestmentProportionOfCashback)) AS CommissionChargable -- Jason Shipp 08/11/2019
			 , CONVERT(MONEY, NULL) AS CashbackEarned
			 , CONVERT(INT, NULL) AS IronOfferID
			 , CONVERT(INT, t.ActivationDays) AS ActivationDays
			 , CONVERT(INT, NULL) AS AboveBase
		FROM #SLC_Match m
		INNER JOIN #SLC_Trans t
			ON t.MatchID = m.ID
		INNER JOIN [Relational].[Customer] c
			ON t.FanID = c.FanID
		INNER JOIN [APW].[DirectLoad_OutletOinToPartnerID] o 
			ON m.DirectDebitOriginatorID = o.DirectDebitOriginatorID -- Captures MFDD transactions --  (Change ID 1)
			AND (o.PartnerCommissionRuleID IS NULL OR m.PartnerCommissionRuleID = o.PartnerCommissionRuleID)
		LEFT JOIN [Staging].[MatchCardHolderPresent] MCHP
			ON t.MatchID = MCHP.MatchID
		LEFT JOIN SLC_Report.dbo.TransactionType tt ON t.TypeID = tt.ID -- Jason Shipp 08/11/2019
		WHERE NOT EXISTS (	SELECT 1
							FROM [Relational].[PartnerTrans] pt
							WHERE m.ID = pt.MatchID)
		AND t.TypeID <> 24
		AND m.VectorID = 40
		AND (o.StartDate IS NULL OR m.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 15/03/2019
		AND (o.EndDate IS NULL OR m.TransactionDate <= o.EndDate)

		/*--------------------------------------------------------------------------*/
		/*--------------Enhance Data in Staging - Start - PartnerTrans--------------*/
		/*--------------------------------------------------------------------------*/
	

		IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match -- Rory 27/05/2019
		SELECT pt.MatchID
			 , ma.RetailOutletID
			 , ma.DirectDebitOriginatorID
			 , ma.VectorID
		INTO #Match
		FROM Staging.PartnerTrans pt
		INNER JOIN #SLC_Match ma
			ON pt.MatchID = ma.ID;

		CREATE CLUSTERED INDEX CIX_MatchID ON #Match (MatchID);



		SET DATEFIRST 1; --set the first day of the week to Monday. This influences the return value of DATEPART()
	
		UPDATE [Staging].[PartnerTrans]
		SET	TransactionWeekStarting = DATEADD(dd, - 1 * (DATEPART(dw, TransactionDate) - 1) , TransactionDate)
		  , TransactionMonth = MONTH(TransactionDate)
		  , TransactionYear = YEAR(TransactionDate)
		  , TransactionWeekStartingCampaign = CASE
													WHEN DATEADD(dd, 3, DATEADD(dd, - 1 * (DATEPART(dw, TransactionDate) - 1) , TransactionDate)) > TransactionDate THEN DATEADD(dd,-4,DATEADD(dd, - 1 * (DATEPART(dw, TransactionDate) - 1) , TransactionDate))
													ELSE DATEADD(dd, 3, DATEADD(dd, - 1 * (DATEPART(dw, TransactionDate) - 1) , TransactionDate))
											  END
		  , AddedWeekStarting = DATEADD(dd, - 1 * (DATEPART(dw, AddedDate) - 1) , AddedDate)
		  , AddedMonth = MONTH(AddedDate)
		  , AddedYear = YEAR(AddedDate)
		  , ExtremeValueFlag = 0
		  , EligibleForCashBack = CASE WHEN [Status] = 1 AND RewardStatus IN (0,1) THEN 1 ELSE 0 END
		  , CommissionChargable = CASE WHEN CommissionChargable IS NOT NULL THEN CommissionChargable ELSE (CASE WHEN [Status] = 1 AND RewardStatus IN (0,1) THEN 1 ELSE 0 END * AffiliateCommissionAmount) END -- Jason Shipp 08/11/2019

		IF OBJECT_ID('tempdb..#CBEarned') IS NOT NULL DROP TABLE #CBEarned
		SELECT DISTINCT
			   MatchID
			 , CASE
					WHEN tr.ClubCash IS NULL THEN 0
					ELSE tr.ClubCash * tt.Multiplier
			   END AS CashBackEarned
		INTO #CBEarned
		FROM #SLC_Trans tr
		INNER JOIN [SLC_Report].[dbo].[TransactionType] tt
			ON tr.TypeID = tt.ID
		WHERE NOT (tr.VectorID = 40 AND tr.TypeID = 24)
		AND EXISTS (SELECT 1
					FROM [Staging].[PartnerTrans] pt
					WHERE tr.MatchID = pt.MatchID)

		UPDATE	t
		SET t.PartnerID = pcr.PartnerID
		  , t.IronOfferID = pcr.RequiredIronOfferID
		FROM [Staging].[PartnerTrans] t
		INNER JOIN [SLC_Report].[dbo].[PartnerCommissionRule] pcr 
			ON t.PartnerCommissionRuleID = pcr.ID
		WHERE pcr.TypeID = 2
		AND (t.[Status] = 1 AND t.[RewardStatus] IN (0, 1));

		UPDATE	t
		SET t.PartnerID = o.PartnerID
		FROM [Staging].[PartnerTrans] t
		INNER JOIN #Match m
			on t.MatchID = m.MatchID
		INNER JOIN [APW].[DirectLoad_OutletOinToPartnerID] o
			ON COALESCE(m.RetailOutletID, m.DirectDebitOriginatorID) = COALESCE(o.OutletID, o.DirectDebitOriginatorID) -- Captures POS and MFDD transactions -- Jason Shipp 15/05/2019
		WHERE (t.[Status] = 1 AND t.[RewardStatus] IN (0, 1))
		AND t.PartnerID IS NULL;

		UPDATE	t
		SET t.IronOfferID = pcr.RequiredIronOfferID
		FROM [Staging].[PartnerTrans] t
		INNER JOIN #Match m
			on t.MatchID = m.MatchID
		INNER JOIN [APW].[DirectLoad_OutletOinToPartnerID] o
			ON COALESCE(m.RetailOutletID, m.DirectDebitOriginatorID) = COALESCE(o.OutletID, o.DirectDebitOriginatorID) -- Captures POS and MFDD transactions -- Jason Shipp 15/05/2019
		LEFT JOIN [SLC_Report].[dbo].[PartnerCommissionRule] pcr 
			ON (t.PartnerCommissionRuleID = pcr.ID) OR (m.VectorID = 40 AND o.PartnerID = pcr.PartnerID AND o.IronOfferID = pcr.RequiredIronOfferID) -- Jason Shipp 11/07/2019
		WHERE pcr.TypeID = 2
		AND (t.[Status] = 1 AND t.[RewardStatus] IN (0, 1))
		AND t.IronOfferID IS NULL;

		UPDATE	t
		SET t.IsOnline = CASE 
						 	WHEN OIN IS NOT NULL THEN 1
						 	WHEN o.PartnerID = 3724 AND o.Channel = 1 THEN 1	--	National Car Parks Ltd
						 	WHEN t.CardholderPresentData = '5' THEN 1
						 	WHEN t.CardholderPresentData = '9' AND o.Channel = 1 THEN 1
						 	ELSE 0 
						 END
		  , t.CashbackEarned = Case
									WHEN CBEarned.CashBackEarned IS NULL THEN 0
									ELSE CBEarned.CashBackEarned
							   END
		FROM [Staging].[PartnerTrans] t
		INNER JOIN #Match m
			on t.MatchID = m.MatchID
		INNER JOIN [APW].[DirectLoad_OutletOinToPartnerID] o
			ON COALESCE(m.RetailOutletID, m.DirectDebitOriginatorID) = COALESCE(o.OutletID, o.DirectDebitOriginatorID) -- Captures POS and MFDD transactions -- Jason Shipp 15/05/2019
		LEFT JOIN #CBEarned CBEarned -- Jason Shipp 15/05/2019
			ON t.MatchID = CBEarned.MatchID
		WHERE (t.[Status] = 1 AND t.[RewardStatus] IN (0, 1))
		
		DELETE
		FROM [Staging].[PartnerTrans]
		WHERE PartnerID IS NULL;
		
		DELETE
		FROM [Staging].[PartnerTrans]
		WHERE CashbackEarned IS NULL;

		--Flag the extreme values on the transactions

		if object_id('tempdb..#temp1') is not null drop table #temp1;

		select	t.MatchID,
				t.PartnerID,
				t.TransactionAmount,
				ntile(100) over (partition by PartnerID order by TransactionAmount, MatchID) ValuePercentile
		into	#temp1
		from	staging.PartnerTrans t with (nolock)
		order by PartnerID;

		update	tr
		set		tr.ExtremeValueFlag = 1
		from	staging.PartnerTrans tr
				inner join #temp1 te
					 on tr.MatchID = te.MatchID
		where	te.ValuePercentile in (1,2,3,4,5,96,97,98,99,100);		--Top and bottom 5% of transactions are flagged as extreme values

		---------------------------------------------------------------------------------------------------------------------
		------------------------------------------Calculating the Above Base Field-------------------------------------------
		---------------------------------------------------------------------------------------------------------------------
		--Work Out above base or not Pre Launch
		--This section adds a customer segment and the base cashback rate IF the transactions meets the where clause 
	
		if object_id ('tempdb..#PtSeg') is not null drop table #PtSeg;

		SELECT	pt.MatchID,
			Cast(CASE	
				WHEN CashBackEarned > 0 and CashbackEarned > Cast(TransactionAmount * (pb.CashBackRateNumeric+0.005) AS NUMERIC(36,2)) THEN 1
				WHEN CashBackEarned < 0 and CashbackEarned < Cast(TransactionAmount * (pb.CashBackRateNumeric+0.005) AS NUMERIC(36,2)) THEN 1
				ELSE 0
			END as Int) as AboveBase
		Into #PtSeg
		FROM staging.partnertrans as pt with (nolock)
		Inner join Relational.Customer_Segment cs with (nolock)
			ON pt.FanID = cs.FanID
			AND pt.PartnerID = cs.PartnerID
		Inner JOIN Relational.Partner_BaseOffer pb with (nolock)
			ON cs.OfferID = pb.OfferID
		WHERE (	(TransactionDate >= pb.StartDate AND pb.EndDate IS NULL) OR 
				(TransactionDate >= pb.StartDate AND TransactionDate <= pb.EndDate)
			  ) and
				pt.EligibleForCashBack = 1 and 
				CashbackEarned <> 0;
		--(2570883 row(s) affected)
		--20 secs
	
		----------------------------------------------------------------------
		---------Work Out above base or not Post Launch-----------------------
		----------------------------------------------------------------------
	
		--This adds a cashback rate if the transaction is post launch
	
		if object_id ('tempdb..#PTWithPostLaunchCBR') is not null drop table #PTWithPostLaunchCBR;

		SELECT	Distinct
			pt.MatchID,
			Cast(CASE	
					WHEN CashBackEarned > 0 and CashbackEarned > Cast(TransactionAmount * (po.CashBackRateNumeric+0.005) AS NUMERIC(36,2)) THEN 1
					WHEN CashBackEarned < 0 and CashbackEarned < Cast(TransactionAmount * (po.CashBackRateNumeric+0.005) AS NUMERIC(36,2)) THEN 1
					ELSE 0
			END as Int) as AboveBase
		INTO #PTWithPostLaunchCBR
		FROM staging.partnertrans as pt with (nolock)
		Inner join Relational.PartnerOffers_Base po  with (nolock)
			ON pt.PartnerID = po.PartnerID AND TransactionDate >= po.StartDate and
				(po.EndDate IS NULL OR TransactionDate <= po.EndDate) and 
				EligibleForCashBack = 1 and CashbackEarned <> 0
		LEFT OUTER JOIN #PtSeg AS PTSEG
			ON PT.MatchID = PTSeg.MatchID
		Where PTSeg.MatchID is null;

		--Select * from #PTWithPostLaunchCBR
		--Select * from #PTseg
		--Where matchid = 102253777
		--(0 row(s) affected)

		----------------------------------------------------------------------
		-----------------Combine two tables together--------------------------
		----------------------------------------------------------------------

		if object_id ('tempdb..#PTWithAB') is not null drop table #PTWithAB
		Select * 
		Into #PTWithAB
		from 
		(SELECT	*
		From #PtSeg
		union all
		Select * 
		from #PTWithPostLaunchCBR
		) as a;

		----------------------------------------------------------------------
		------------------------Do updates------------------------------------
		----------------------------------------------------------------------

		Update staging.PartnerTrans
		Set Abovebase = pt.AboveBase
		FROM staging.PartnerTrans p
		LEFT OUTER JOIN #PTWithAB pt
		ON p.MatchID = pt.MatchID;

		---------------------------------------------------------------------------------------------
		-----------------Set Above Base to 1 for all non coalition partners--------------------------
		---------------------------------------------------------------------------------------------

		Update staging.PartnerTrans
		Set Abovebase = 1
		Where	PartnerID in (Select PartnerID from [Relational].[Partner_CBPDates] Where [Coalition_Member] = 0) 
				and AboveBase is null;

		---------------------------------------------------------------------------------------------
		-----------------Delete not eligible for cashback transactions-------------------------------
		---------------------------------------------------------------------------------------------
	
		Delete from staging.partnertrans
		Where Eligibleforcashback = 0;

		/*--------------------------------------------------------------------------------------------------
		---------------------------Update entry in JobLog Table with End Date-------------------------------
		----------------------------------------------------------------------------------------------------*/
		
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
				TableSchemaName = 'Staging' and
				TableName = 'PartnerTrans' and
				EndDate is null;
	
		/*--------------------------------------------------------------------------------------------------
		---------------------------Update entry in JobLog Table with Row Count------------------------------
		----------------------------------------------------------------------------------------------------*/
		--Count run seperately as when table grows this as a task on its own may take several minutes and we do
		--not want it included in table creation times
	
		Update  staging.JobLog_Temp
		Set		TableRowCount = (Select COUNT(*) from Staging.PartnerTrans)
		where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
				TableSchemaName = 'Staging' and
				TableName = 'PartnerTrans' and
				TableRowCount is null;
		
		/*--------------------------------------------------------------------------------------------------
		-----------------------------Write entry to JobLog Table--------------------------------------------
		----------------------------------------------------------------------------------------------------*/
		
		Insert into staging.JobLog_Temp
		Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'PartnerTrans',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A';
	
		/*--------------------------------------------------------------------------*/
		/*--------------------New Staging.PartnerTrans Primary Key------------------*/
		/*--------------------------------------------------------------------------*/
		/*
		ALTER TABLE Relational.PartnerTrans
		 ADD PRIMARY KEY (MatchID)
		*/	

		/*--------------------------------------------------------------------------*/
		/*--------------Build final tables in relational schema -PartnerTrans-------*/
		/*--------------------------------------------------------------------------*/

		--if object_id('Relational.PartnerTrans') is not null drop table Relational.PartnerTrans	RF Commented out 2nd Feb 2022, to be uncommented out ASAP
		--delete from Relational.PartnerTrans
		--IF @@SERVERNAME != 'DIMAIN2'
		--	BEGIN
		--		ALTER INDEX i_FanID ON Relational.PartnerTrans  DISABLE;
		--		ALTER INDEX i_TranAssessment ON Relational.PartnerTrans  DISABLE;
		--		ALTER INDEX i_TransactionWeekStarting ON Relational.PartnerTrans  DISABLE;
		--	END

		Insert into	Relational.PartnerTrans
		select	DISTINCT
				pt.MatchID,
				pt.FanID,
				pt.PartnerID,
				pt.OutletID,
				pt.IsOnline,
				pt.CardHolderPresentData,
				pt.TransactionAmount,
				pt.ExtremeValueFlag,
				pt.TransactionDate,
				pt.TransactionWeekStarting,
				pt.TransactionMonth,
				pt.TransactionYear,
				pt.TransactionWeekStartingCampaign,
				pt.AddedDate,
				pt.AddedWeekStarting,
				pt.AddedMonth,
				pt.AddedYear,
				pt.status,
				pt.rewardstatus,
				pt.AffiliateCommissionAmount,
				pt.EligibleForCashBack,
				pt.CommissionChargable,
				pt.CashbackEarned,
				pt.IronOfferID,
				pt.ActivationDays,
				pt.AboveBase,
				Case
					When pc.CardTypeID = 1 then 1 -- Credit Card
					When pc.CardTypeID = 2 then 0 -- Debit Card
					When t.DirectDebitOriginatorID IS NOT NULL then 2 -- Direct Debit
					Else 3
				End as PaymentMethodID
		from	staging.PartnerTrans pt
		LEFT join #SLC_Trans as t
			on pt.MatchID = t.MatchID
		LEFT join #SLC_Pan as p
			on t.PanID = p.id
		LEFT join slc_Report..PaymentCard as pc with (nolock)
			on p.PaymentCardID = pc.ID
		--	AND pc.CardTypeid <> 2

		IF @@SERVERNAME = 'DIMAIN2'
			BEGIN
				UPDATE STATISTICS Relational.PartnerTrans 
			END

		----Rebuild Indexes
		--IF @@SERVERNAME != 'DIMAIN2'	RF Commented out 2nd Feb 2022, to be uncommented out ASAP
		--	BEGIN
		--		ALTER INDEX i_FanID ON Relational.PartnerTrans  REBUILD WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON); -- CJM 20190212
		--		ALTER INDEX i_TranAssessment ON Relational.PartnerTrans  REBUILD WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON); -- CJM 20190212
		--		ALTER INDEX i_TransactionWeekStarting ON Relational.PartnerTrans  REBUILD WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON); -- CJM 20190212 
		--	END


		/*--------------------------------------------------------------------------------------------------
		---------------------------Update entry in JobLog Table with End Date-------------------------------
		----------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
				TableSchemaName = 'Relational' and
				TableName = 'PartnerTrans' and
				EndDate is null;
	
		/*--------------------------------------------------------------------------------------------------
		---------------------------Update entry in JobLog Table with Row Count------------------------------
		----------------------------------------------------------------------------------------------------*/
		--Count run seperately as when table grows this as a task on its own may take several minutes and we do
		--not want it included in table creation times
		Update  staging.JobLog_Temp
		Set		TableRowCount = (Select isnull(COUNT(*),0) from Staging.PartnerTrans with (nolock))
		where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
				TableSchemaName = 'Relational' and
				TableName = 'PartnerTrans' and
				TableRowCount is null;
		
		
		Insert into staging.JobLog
		select [StoredProcedureName],
			[TableSchemaName],
			[TableName],
			[StartDate],
			[EndDate],
			[TableRowCount],
			[AppendReload]
		from staging.JobLog_Temp;

		TRUNCATE TABLE staging.JobLog_Temp;

		RETURN 0; -- normal exit here

	END TRY
	BEGIN CATCH		
		
		-- Grab the error details
		SELECT  
			@ERROR_NUMBER = ERROR_NUMBER(), 
			@ERROR_SEVERITY = ERROR_SEVERITY(), 
			@ERROR_STATE = ERROR_STATE(), 
			@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
			@ERROR_LINE = ERROR_LINE(),   
			@ERROR_MESSAGE = ERROR_MESSAGE();
		SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID));

		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
		-- Insert the error into the ErrorLog
		INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
		VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
		SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
		RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
		RETURN -1;
	END CATCH

	RETURN 0; -- should never run

END