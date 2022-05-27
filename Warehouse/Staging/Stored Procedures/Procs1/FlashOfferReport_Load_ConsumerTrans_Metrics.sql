/******************************************************************************
Author: Jason Shipp
Created: 24/05/2018
Purpose:
	- Loads debit card only transaction results per IronOffer for:
		- Warehouse exposed
		- Warehouse control
		- nFI exposed 
		- nFI control 
		- AMEX control
	- Logic limiting transactions to specific retailers carried out when populating the base transaction tables:
		- Warehouse.Staging.FlashOfferReport_ConsumerTransaction
		- Warehouse.Staging.FlashOfferReport_MatchTrans
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 20/07/2019
	- Added logic to check customer transactions based on WHERE EXISTS in the Warehouse.Staging.FlashOfferReport_ExposedControlCustomers table, instead of using joins
	- Avoids duplication when an analysis period covers several offer cycles, and is more efficient

Jason Shipp 12/03/2019
	- Added loop to code, instead of using a Foreach Loop container in SSIS

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_ConsumerTrans_Metrics --(@IronOfferID INT)
	
AS
BEGIN

	SET NOCOUNT ON;

	/******************************************************************************
	Fetch list of distinct IronOfferIDs from Warehouse.Staging.FlashOfferReport_All_Offers 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IronOffers') IS NOT NULL DROP TABLE #IronOffers;

	SELECT
	x.IronOfferID
	, ROW_NUMBER() OVER (ORDER BY x.IronOfferID) AS RowNum
	INTO #IronOffers
	FROM (
		SELECT DISTINCT
			a.IronOfferID 
		FROM Warehouse.Staging.FlashOfferReport_All_Offers a
		WHERE NOT EXISTS (
			SELECT NULL FROM Warehouse.Staging.FlashOfferReport_Metrics m
			WHERE
				a.IronOfferID = m.IronOfferID
				AND a.StartDate = m.StartDate
				AND a.EndDate = m.EndDate
				AND a.PeriodType = m.PeriodType
		)
	) x
	ORDER BY x.IronOfferID;

	/******************************************************************************
	Load exposed and control transaction results into a staging table, iterating over IronOfferIDs
	******************************************************************************/

	DECLARE @RowNumber int;
	DECLARE @MaxRowNumber int;
	DECLARE @IronOfferID int;

	SET @RowNumber = 1;
	SET @MaxRowNumber = (SELECT MAX(RowNum) FROM #IronOffers);

	WHILE @RowNumber <= @MaxRowNumber
	
	BEGIN
		
		SET @IronOfferID = (SELECT IronOfferID FROM #IronOffers WHERE RowNum = @RowNumber);

		-- Use real table as temp table cannot be used as part of SSIS Data Flow task
		IF OBJECT_ID('Warehouse.Staging.FlashOfferReport_ResultsStaging') IS NOT NULL DROP TABLE Warehouse.Staging.FlashOfferReport_ResultsStaging;

		-- CTE: Load distinct details for the IronOfferID (@IronOfferID)
		WITH Offer AS (
			SELECT DISTINCT 
				o.IronOfferID
				, o.StartDate
				, o.EndDate
				, o.PeriodType
				, o.OfferSetupStartDate
				, o.OfferSetupEndDate
				, o.PartnerID
				, o.isWarehouse
				, o.ControlGroupTypeID
				, o.SpendStretch
			FROM Warehouse.Staging.FlashOfferReport_All_Offers o
			WHERE 
				o.IronOfferID = @IronOfferID 
		)
		, OfferWithCycles AS (
			SELECT DISTINCT 
				o.IronOfferID
				, o.IronOfferCyclesID
				, o.ControlGroupID
				, o.StartDate
				, o.EndDate
				, o.PeriodType
				, o.OfferSetupStartDate
				, o.OfferSetupEndDate
				, o.PartnerID
				, o.isWarehouse
				, o.ControlGroupTypeID
				, o.SpendStretch
			FROM Warehouse.Staging.FlashOfferReport_All_Offers o
			WHERE 
				o.IronOfferID = @IronOfferID 
		)
		-- Warehouse exposed
		SELECT
			o.IronOfferID
			, 1 AS Exposed
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, NULL AS Channel
			, NULL AS Cardholders
			, SUM(ct.Amount) AS Sales
			, COUNT(ct.CINID) AS Trans
			, COUNT(DISTINCT ct.CINID) AS Spenders
			, NULL AS Threshold
			, o.OfferSetupStartDate
			, o.OfferSetupEndDate
			, o.PartnerID
			, o.isWarehouse
			, NULL AS ControlGroupTypeID
		INTO Warehouse.Staging.FlashOfferReport_ResultsStaging
		FROM Offer o
		LEFT JOIN Warehouse.Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the offer started 
			ON o.PartnerID = oe.PartnerID
			AND o.OfferSetupStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE())
		LEFT JOIN Warehouse.Staging.FlashOfferReport_ConsumerTransaction ct with (nolock) 
			ON ct.TranDate BETWEEN o.StartDate AND o.EndDate
			AND ct.Amount > 0 AND ct.Amount < oe.UpperValue
			AND ct.PartnerID = o.PartnerID
		WHERE
			o.ControlGroupTypeID = 0 -- Exposed results will be the same for in/out of programme control groups, so arbitrarily use OOP
			AND o.IsWarehouse = 1
			--AND (ct.Amount >= o.SpendStretch OR o.SpendStretch IS NULL)
			AND EXISTS (
				SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
				INNER JOIN OfferWithCycles ocyc
					ON c.GroupID = ocyc.IronOfferCyclesID
					AND c.IsWarehouse = ocyc.IsWarehouse
					AND ocyc.ControlGroupTypeID = 0
				WHERE 
					ct.CINID = c.CINID
					AND c.Exposed = 1
					AND o.IsWarehouse = c.IsWarehouse -- NULL isWarehouse entries (AMEX) will not be returned
					AND ocyc.StartDate = o.StartDate
					AND ocyc.EndDate = o.EndDate
					AND o.ControlGroupTypeID = 0 -- Exposed results will be the same for in/out of programme control groups, so arbitrarily use OOP
			)
		GROUP BY
			o.IronOfferID, o.StartDate, o.EndDate, o.PeriodType, o.OfferSetupStartDate, o.OfferSetupEndDate, o.PartnerID, o.isWarehouse, o.ControlGroupTypeID

		UNION ALL

		-- Warehouse control and nFI control
		SELECT
			o.IronOfferID
			, 0 AS Exposed
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, NULL AS Channel
			, NULL AS Cardholders
			, SUM(ct.Amount) AS Sales
			, COUNT(ct.CINID) AS Trans
			, COUNT(DISTINCT ct.CINID) AS Spenders
			, NULL AS Threshold
			, o.OfferSetupStartDate
			, o.OfferSetupEndDate
			, o.PartnerID
			, o.isWarehouse
			, o.ControlGroupTypeID
		FROM Offer o
		LEFT JOIN Warehouse.Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the offer started 
			ON o.PartnerID = oe.PartnerID
			AND o.OfferSetupStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE())
		LEFT JOIN Warehouse.Staging.FlashOfferReport_ConsumerTransaction ct with (nolock) 
			ON ct.TranDate BETWEEN o.StartDate AND o.EndDate
			AND ct.Amount > 0 AND ct.Amount < oe.UpperValue
			AND ct.PartnerID = o.PartnerID
		WHERE
			o.IsWarehouse IS NOT NULL
			--AND (ct.Amount >= o.SpendStretch OR o.SpendStretch IS NULL)
			AND EXISTS (
				SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
				INNER JOIN OfferWithCycles ocyc
					ON c.GroupID = ocyc.ControlGroupID
					AND c.IsWarehouse = ocyc.IsWarehouse
					AND c.ControlGroupTypeID = c.ControlGroupTypeID
				WHERE 
					ct.CINID = c.CINID
					AND c.Exposed = 0
					AND o.IsWarehouse = c.IsWarehouse -- NULL isWarehouse entries (AMEX) will not be returned
					AND ocyc.StartDate = o.StartDate
					AND ocyc.EndDate = o.EndDate
					AND o.ControlGroupTypeID = c.ControlGroupTypeID
			)
		GROUP BY
			o.IronOfferID, o.StartDate, o.EndDate, o.PeriodType, o.OfferSetupStartDate, o.OfferSetupEndDate, o.PartnerID, o.isWarehouse, o.ControlGroupTypeID

		UNION ALL

		-- AMEX control results
		SELECT
			o.IronOfferID
			, 0 AS Exposed
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, NULL AS Channel
			, NULL AS Cardholders
			, SUM(ct.Amount) AS Sales
			, COUNT(ct.CINID) AS Trans
			, COUNT(DISTINCT ct.CINID) AS Spenders
			, NULL AS Threshold
			, o.offerSetupStartDate
			, o.OfferSetupEndDate
			, o.PartnerID
			, o.isWarehouse
			, o.ControlGroupTypeID
		FROM Offer o
		LEFT JOIN Warehouse.Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the offer started 
			ON o.PartnerID = oe.PartnerID
			AND o.OfferSetupStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE())
		LEFT JOIN Warehouse.Staging.FlashOfferReport_ConsumerTransaction ct WITH (NOLOCK) 
			ON ct.TranDate BETWEEN o.StartDate AND o.EndDate
			AND ct.Amount > ISNULL(o.SpendStretch, 0) AND ct.Amount < oe.UpperValue -- Non-outlier above spendstretch transactions
			AND ct.PartnerID = o.PartnerID
		WHERE
			o.IsWarehouse IS NULL
			--AND (ct.Amount >= o.SpendStretch OR o.SpendStretch IS NULL)
			AND EXISTS (
				SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
				INNER JOIN OfferWithCycles ocyc
					ON c.GroupID = ocyc.ControlGroupID
					AND (c.IsWarehouse IS NULL AND ocyc.IsWarehouse IS NULL)
					AND c.ControlGroupTypeID = c.ControlGroupTypeID
				WHERE 
					ct.CINID = c.CINID
					AND c.Exposed = 0
					AND (o.IsWarehouse IS NULL AND c.IsWarehouse IS NULL)
					AND ocyc.StartDate = o.StartDate
					AND ocyc.EndDate = o.EndDate
					AND o.ControlGroupTypeID = c.ControlGroupTypeID
			)
		GROUP BY
			o.IronOfferID, o.StartDate, o.EndDate, o.PeriodType, o.OfferSetupStartDate, o.OfferSetupEndDate, o.PartnerID, o.isWarehouse, o.ControlGroupTypeID

		UNION ALL

		-- nFI exposed results
		SELECT
			o.IronOfferID
			, 1 AS Exposed
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, NULL AS Channel
			, NULL AS Cardholders
			, SUM(mt.Spend) AS Sales
			, COUNT(mt.FanID) AS Trans
			, COUNT(DISTINCT mt.FanID) AS Spenders
			, NULL AS Threshold
			, o.OfferSetupStartDate
			, o.OfferSetupEndDate
			, o.PartnerID
			, o.isWarehouse
			, NULL AS ControlGroupTypeID
		FROM Offer o
		LEFT JOIN Warehouse.Staging.OfferReport_OutlierExclusion oe -- Get outlier exclusion values based on when the offer started 
			ON o.PartnerID = oe.PartnerID
			AND o.OfferSetupStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE())
		LEFT JOIN Warehouse.Staging.FlashOfferReport_MatchTrans mt 
			ON mt.TranDate BETWEEN o.StartDate and o.EndDate
			AND mt.Spend > 0 AND mt.Spend < oe.UpperValue
			AND mt.PartnerID = o.PartnerID
		WHERE 
			o.ControlGroupTypeID = 0 -- Exposed results will be the same for in/out of programme control groups, so arbitrarily use OOP
			AND o.IsWarehouse = 0
			--AND (mt.Spend >= o.SpendStretch OR o.SpendStretch IS NULL)
			AND EXISTS (
				SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
				INNER JOIN OfferWithCycles ocyc
					ON c.GroupID = ocyc.IronOfferCyclesID
					AND c.IsWarehouse = ocyc.IsWarehouse
					AND ocyc.ControlGroupTypeID = 0
				WHERE
					mt.FanID = c.FanID
					AND c.Exposed = 1
					AND o.IsWarehouse = c.IsWarehouse -- NULL isWarehouse entries (AMEX) will not be returned
					AND ocyc.StartDate = o.StartDate
					AND ocyc.EndDate = o.EndDate
					AND o.ControlGroupTypeID = 0 -- Exposed results will be the same for in/out of programme control groups, so arbitrarily use OOP
			)
		GROUP BY
			o.IronOfferID, o.StartDate, o.EndDate, o.PeriodType, o.OfferSetupStartDate, o.OfferSetupEndDate, o.PartnerID, o.isWarehouse

		UNION ALL

		-- AMEX exposed results
		SELECT
			o.IronOfferID
			, 1 Exposed
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, NULL AS Channel
			, NULL AS Cardholders
			, SUM(mt.Spend) AS Sales
			, COUNT(mt.FanID) AS Trans
			, COUNT(DISTINCT mt.FanID) AS Spenders
			, NULL AS Threshold
			, o.OfferSetupStartDate
			, o.OfferSetupEndDate
			, o.PartnerID
			, o.isWarehouse
			, NULL AS ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_Offers o
		LEFT JOIN Warehouse.Staging.OfferReport_OutlierExclusion oe
			ON o.PartnerID = oe.PartnerID
			AND o.OfferSetupStartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE())
		LEFT JOIN Warehouse.APW.SchemeTrans_Pipe mt
			ON mt.TranDate BETWEEN o.StartDate AND o.EndDate
			AND mt.RetailerID = o.PartnerID
			AND mt.Spend > 0 AND mt.Spend < oe.UpperValue
			AND mt.IronOfferID = o.IronOfferID
			AND mt.IsRetailerReport = 1
		WHERE
			o.isWarehouse IS NULL
			AND o.IronOfferID = @IronOfferID
			AND o.ControlGroupTypeID = 0 -- Exposed results will be the same for in/out of programme control groups, so arbitrarily use OOP
			--AND (mt.Spend >= o.SpendStretch OR o.SpendStretch IS NULL)
		GROUP BY
			o.IronOfferID, o.StartDate, o.EndDate, o.PeriodType, o.OfferSetupStartDate, o.OfferSetupEndDate, o.PartnerID, o.isWarehouse
		OPTION(RECOMPILE);

		/******************************************************************************
		Fetch newly-calculated exposed and control transaction results

		-- Create table for storing results (insert done using SSIS package)

		CREATE TABLE Warehouse.Staging.FlashOfferReport_Metrics (
			ID int IDENTITY (1, 1)
			, IronOfferID int
			, Exposed bit
			, StartDate date
			, EndDate date
			, PeriodType varchar(25)
			, Channel int
			, Cardholders int
			, Sales money
			, Trans int
			, Spenders int
			, Threshold money
			, OfferSetupStartDate date
			, OfferSetupEndDate date
			, PartnerID int
			, isWarehouse bit
			, ControlGroupTypeID int
			, CalculationDate date
			, CONSTRAINT PK_FlashOfferReport_Metrics PRIMARY KEY CLUSTERED (ID)
		)
		******************************************************************************/

		INSERT INTO Warehouse.Staging.FlashOfferReport_Metrics (
			IronOfferID
			, Exposed
			, StartDate
			, EndDate
			, PeriodType
			, Channel
			, Cardholders
			, Sales
			, Trans
			, Spenders
			, Threshold
			, OfferSetupStartDate
			, OfferSetupEndDate
			, PartnerID
			, isWarehouse
			, ControlGroupTypeID
			, CalculationDate
		)
		SELECT 
			s.IronOfferID
			, s.Exposed
			, s.StartDate
			, s.EndDate
			, s.PeriodType
			, s.Channel
			, s.Cardholders
			, s.Sales
			, s.Trans
			, s.Spenders
			, s.Threshold
			, s.OfferSetupStartDate
			, s.OfferSetupEndDate
			, s.PartnerID
			, s.isWarehouse
			, s.ControlGroupTypeID
			, CAST(GETDATE() AS date) AS CalculationDate
		FROM Warehouse.Staging.FlashOfferReport_ResultsStaging s
		WHERE NOT EXISTS (
			SELECT NULL FROM Warehouse.Staging.FlashOfferReport_Metrics x
			WHERE
				s.IronOfferID = x.IronOfferID
				AND s.ControlGroupTypeID = x.ControlGroupTypeID
				AND s.Exposed = x.Exposed
				AND s.isWarehouse = x.isWarehouse
				AND s.StartDate = x.StartDate
				AND s.EndDate = x.StartDate
				AND s.PeriodType = x.PeriodType
				AND CAST(GETDATE() AS date) = x.CalculationDate
			);
		
		SET @RowNumber = @RowNumber + 1; 

	END

END