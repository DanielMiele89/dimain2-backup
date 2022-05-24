/******************************************************************************
Author:		Rory Francis
Created:	2020-12-21
Purpose:	Fetch Merchant Funded Direct Debit exposed transaction file
	
------------------------------------------------------------------------------
Modification History
	
******************************************************************************/

CREATE PROCEDURE [Staging].[DirectDebitResults_TransactionFile_Fetch_20210513] (@RetailerID INT)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	---- For testing 
	--DECLARE @RetailerID int = 4846; -- Sky primary PartnerID
	DECLARE @DateFirst int = 1; -- For setting Friday as the first day of the week
	DECLARE @MinStartDate date = '2020-11-19'; -- Sky go live date

	SET DATEFIRST @DateFirst; -- Set Friday as the first day of the week
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);

	DECLARE @MaxEndDate date = DATEADD(day, -1, @Today);
	
	/******************************************************************************
	Load PartnerIDs
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs;
	SELECT	@RetailerID AS PartnerID
		,	@RetailerID AS RetailerID -- Primary PartnerID
	INTO #PartnerIDs
	UNION
	SELECT	PartnerID -- Alternate PartnerIDs
		,	@RetailerID AS RetailerID
	FROM [Warehouse].[APW].[PartnerAlternate] 
	WHERE AlternatePartnerID = @RetailerID
	UNION 
	SELECT	PartnerID -- Alternate PartnerIDs
		,	@RetailerID AS RetailerID
	FROM [nFI].[APW].[PartnerAlternate] 
	WHERE AlternatePartnerID = @RetailerID;

	CREATE CLUSTERED INDEX CIX_PartnerIDs ON #PartnerIDs (PartnerID);

	/******************************************************************************
	Load direct debit identification numbers (OINs) 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#DDSuppliers') IS NOT NULL DROP TABLE #DDSuppliers;

	SELECT	DISTINCT
			s.PartnerID
		,	oin.OIN
		,	o.ID AS DirectDebitOriginatorID
		,	NULL AS StartDate
		,	NULL AS EndDate
	INTO #DDSuppliers
	FROM [SLC_Report].[dbo].[DirectDebitOfferOINs] oin -- Repoint to Warehouse.Relational.DirectDebit_MFDD_IncentivisedOINs if OINs start starting/ending whilst offers are active
	INNER JOIN [SLC_Report].[dbo].[DirectDebitOriginator] o 
		ON oin.OIN = o.OIN
	INNER JOIN [Relational].[IronOfferSegment] s
		ON oin.IronOfferID = s.IronOfferID
	WHERE EXISTS (	SELECT 1
					FROM #PartnerIDs pa
					WHERE s.PartnerID = pa.PartnerID);

	CREATE CLUSTERED INDEX CIX_DDSuppliers ON #DDSuppliers (DirectDebitOriginatorID, StartDate, EndDate);
	CREATE NONCLUSTERED INDEX IX_DDSuppliers ON #DDSuppliers (OIN);

	/******************************************************************************
	Load business rules
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Rules') IS NOT NULL DROP TABLE #Rules;
	SELECT	ddo.ID AS DirectDebitOriginatorID
		,	ddo.OIN
		,	CONVERT(VARCHAR(50), oin.IronOfferID) AS IronOfferID
		,	o2.PartnerID
		,	pcr.ID AS PartnerCommissionRuleID
		,	o2.StartDate AS OfferStartDate
		,	o2.EndDate AS OfferEndDate
		,	o.MaximumEarningDDDelay
	INTO #Rules
	FROM [SLC_Report].[dbo].[DirectDebitOfferOINs] oin
	INNER JOIN [SLC_Report].[dbo].[DirectDebitOriginator] ddo
		ON oin.OIN = ddo.OIN
	INNER JOIN [SLC_Report].[dbo].[DirectDebitOffers] o
		ON oin.IronOfferID = o.IronOfferID
	INNER JOIN [Relational].[IronOffer] o2
		ON oin.IronOfferID = o2.IronOfferID
	INNER JOIN #DDSuppliers dds
		ON ddo.OIN = dds.OIN
	LEFT JOIN [SLC_Report].[dbo].[PartnerCommissionRule] pcr
		ON oin.IronOfferID = pcr.RequiredIronOfferID
		AND pcr.TypeID = 2;

	CREATE CLUSTERED INDEX CIX_Rules ON #Rules (DirectDebitOriginatorID, PartnerCommissionRuleID);
	CREATE NONCLUSTERED INDEX IX_Rules ON #Rules (IronOfferID);
	CREATE NONCLUSTERED INDEX UIX_Rules ON #Rules (OIN);

	/******************************************************************************
	Load calendar table containing start and end dates within the analysis period
	******************************************************************************/

	DECLARE @PastWeeksToCalculate int = (SELECT CEILING(MAX(MaximumEarningDDDelay)/CAST(7 AS float)) FROM #Rules); -- Weeks over which to analyse. Weeks before this should not change, so can be taken from previous calculations

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
	
	-- For weekly analysis periods

	WITH 
	E1			AS	(	SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),
	E2			AS	(	SELECT n = 0 FROM E1 a CROSS JOIN E1 b),
	Tally		AS	(	SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b), -- Create table of numbers
	TallyDates	AS	(	SELECT n, CalDate = DATEADD(day, n, @MinStartDate) FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= @MaxEndDate) -- Create table of consecutive dates
	
	SELECT	DISTINCT
			CASE 
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) < @MinStartDate
				THEN @MinStartDate -- Don't let StartDate go before analysis start date
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) 
			END	AS StartDate -- For each calendar date in #Dates, minus days since the most recent Monday  
		,	CASE
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) > @MaxEndDate
				THEN @MaxEndDate
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate)
			END AS EndDate -- For each calendar date in #Dates, minus days since the most recent Sunday
	INTO #Calendar
	FROM TallyDates
	WHERE CalDate >= (DATEADD(week, -@PastWeeksToCalculate, @Today)) -- Only include the x most recent complete weeks, where x is the number of weeks in the Incentivised DD tracking window. Within this window, customers can change CustomerGroup
	
	CREATE CLUSTERED INDEX CIX_Calendar ON #Calendar (StartDate, EndDate);

	/******************************************************************************
	Load IronOffer References (IronOfferCycles and ControlGroupIDs)
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IronOfferReferences') IS NOT NULL DROP TABLE #IronOfferReferences;
	SELECT	p.RetailerID
		,	CONVERT(VARCHAR(50), o.IronOfferID) AS IronOfferID
		,	cal.StartDate
		,	cal.EndDate
	INTO #IronOfferReferences
	FROM #Rules o
	INNER JOIN #Calendar cal -- Offers overlapping analysis period
		ON (o.OfferStartDate <= cal.EndDate OR cal.EndDate IS NULL)
		AND (o.OfferEndDate >= @MinStartDate OR o.OfferEndDate IS NULL OR cal.StartDate IS NULL) -- Jason Shipp 01/05/2019- Used @MinStartDate as anchor for determining all exposed/control members to date
	INNER JOIN (SELECT IronOfferID, MAX(MaximumEarningDDDelay) AS MaximumEarningDDDelay FROM #Rules GROUP BY IronOfferID) r
		ON CAST(o.IronOfferID AS VARCHAR(50)) = r.IronOfferID
	INNER JOIN #PartnerIDs p
		ON o.PartnerID = p.PartnerID;
	
	/******************************************************************************
	Load transaction period
	******************************************************************************/
	
	IF OBJECT_ID('tempdb..#IterationTable') IS NOT NULL DROP TABLE #IterationTable;
	SELECT	ior.RetailerID
		,	ior.IronOfferID
		,	ior.StartDate
		,	ior.EndDate
		,	ROW_NUMBER() OVER (ORDER BY ior.RetailerID, ior.IronOfferID, ior.StartDate DESC, ior.EndDate) AS RowNum
	INTO #IterationTable
	FROM #IronOfferReferences ior;

	DELETE
	FROM #IterationTable
	WHERE RowNum > 1
	
	/******************************************************************************
	Load Match transactions
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match;
	SELECT	ma.ID
		 ,	ru.OIN
		 ,	CONVERT(DATE, ma.TransactionDate) AS TransactionDate
		 ,	ba.MaskedAccountNumber
		 ,	ba.EncryptedAccountNumber
		 ,	ma.Amount AS AmountSpent
		 ,	ru.IronOfferID AS OfferCode
		 ,	CONVERT(VARCHAR(5), ROUND(ma.PartnerCommissionRate, 2)) AS CommissionRate
		 ,	ISNULL(ma.PartnerCommissionAmount, 0) - ISNULL(ma.VatAmount, 0) AS NetAmount
		 ,	ISNULL(ma.VatAmount, 0) AS VatAmount
		 ,	ISNULL(ma.PartnerCommissionAmount, 0) AS GrossAmount
		 ,	fa.ID AS FanID
	INTO #Match
	FROM [SLC_Report].[dbo].[Match] ma
	INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba 
		ON ma.IssuerBankAccountID = iba.ID
	INNER JOIN [SLC_Report].[dbo].[BankAccount] ba 
		ON iba.BankAccountID = ba.ID
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic 
		ON iba.IssuerCustomerID = ic.ID
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON ic.SourceUID = fa.SourceUID
		AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
	INNER JOIN #Rules ru
		ON ma.PartnerCommissionRuleID = ru.PartnerCommissionRuleID
	WHERE ma.[Status] = 1 -- Valid transactions
	AND ma.[RewardStatus] IN (1, 15) -- 15 = insufficient prior DD transactions for incentivisation, 1 = incentivised DD transaction
	AND ma.VectorID = 40 -- RBS DDs
	AND EXISTS (	SELECT 1
					FROM #IterationTable it
					WHERE ma.TransactionDate BETWEEN it.StartDate AND it.EndDate)
		
	CREATE CLUSTERED INDEX CIX_MatchID ON #Match (FanID, ID);


	/******************************************************************************
	Join with Trans for output
	******************************************************************************/
	
	IF OBJECT_ID('tempdb..##Output') IS NOT NULL DROP TABLE ##Output;
	SELECT	ma.ID AS MatchID
		 ,	ma.OIN
		 ,	ma.TransactionDate
		 ,	ma.MaskedAccountNumber
		 ,	ma.EncryptedAccountNumber
		 ,	ma.AmountSpent
		 ,	ma.OfferCode
		 ,	tr.ClubCash AS CashbackEarned
		 ,	ma.NetAmount / tr.ClubCash - 1 AS CommissionRate
		 ,	ma.NetAmount
		 ,	ma.VatAmount
		 ,	ma.GrossAmount
	INTO ##Output
	FROM #Match ma
	INNER JOIN [SLC_Report].[dbo].[Trans] tr
		ON ma.ID = tr.MatchID
		AND ma.FanID = tr.FanID
		AND tr.ID > 1003732778
		AND EXISTS (	SELECT 1
						FROM #IterationTable it
						WHERE tr.Date BETWEEN it.StartDate AND it.EndDate)

	CREATE CLUSTERED INDEX CIX_DateAmount ON ##Output (TransactionDate, AmountSpent);


	/******************************************************************************
	Create CSV Output query
	******************************************************************************/
	
		DECLARE @FileContents VARCHAR(MAX)

		SET @FileContents = '
			Set NOCOUNT ON;

			SELECT	CONVERT(VARCHAR(MAX), ''MatchID'')
				,	CONVERT(VARCHAR(MAX), ''OIN'')
				,	CONVERT(VARCHAR(MAX), ''TransactionDate'')
				,	CONVERT(VARCHAR(MAX), ''MaskedAccountNumber'')
				,	CONVERT(VARCHAR(MAX), ''EncryptedAccountNumber'')
				,	CONVERT(VARCHAR(MAX), ''AmountSpent'')
				,	CONVERT(VARCHAR(MAX), ''OfferCode'')
				,	CONVERT(VARCHAR(MAX), ''CashbackEarned'')
				,	CONVERT(VARCHAR(MAX), ''CommissionRate'')
				,	CONVERT(VARCHAR(MAX), ''NetAmount'')
				,	CONVERT(VARCHAR(MAX), ''VatAmount'')
				,	CONVERT(VARCHAR(MAX), ''GrossAmount'')

			UNION ALL

			SELECT	CONVERT(VARCHAR(MAX), MatchID)
				,	CONVERT(VARCHAR(MAX), OIN)
				,	CONVERT(VARCHAR(MAX), TransactionDate)
				,	CONVERT(VARCHAR(MAX), MaskedAccountNumber)
				,	CONVERT(VARCHAR(MAX), EncryptedAccountNumber, 2)
				,	CONVERT(VARCHAR(MAX), AmountSpent)
				,	CONVERT(VARCHAR(MAX), OfferCode)
				,	CONVERT(VARCHAR(MAX), CashbackEarned)
				,	CONVERT(VARCHAR(MAX), CommissionRate)
				,	CONVERT(VARCHAR(MAX), NetAmount)
				,	CONVERT(VARCHAR(MAX), VatAmount)
				,	CONVERT(VARCHAR(MAX), GrossAmount)
			FROM ##Output'


	/******************************************************************************
	Build email contents
	******************************************************************************/
	
		DECLARE @EmailMessage VARCHAR(MAX)
		SET @EmailMessage = 'Hi there, '
		+ '<br><br>' + 
		'Please see attached the transaction file for ' + (SELECT Name FROM [SLC_REPL].[dbo].[Partner] WHERE ID = @RetailerID) + ' showing transactions between ' + (SELECT CONVERT(VARCHAR(MAX), MIN(StartDate), 113) FROM #IterationTable) + ' and ' + (SELECT CONVERT(VARCHAR(MAX), MAX(EndDate), 113) FROM #IterationTable) + '.'
		+ '<br><br>' + 
		'Kind Regards,'
		+ '<br>' +
		'Data Ops'

		DECLARE @EmailSubject VARCHAR(MAX)
		SET @EmailSubject = (SELECT Name FROM [SLC_REPL].[dbo].[Partner] WHERE ID = @RetailerID) + ' Direct Debit Transaction File was executed at ' + CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)

		DECLARE @FileName VARCHAR(MAX)
		SET @FileName = (SELECT Name FROM [SLC_REPL].[dbo].[Partner] WHERE ID = @RetailerID) + ' Transaction File.csv'
		
		PRINT @EmailMessage

	/******************************************************************************
	Build Recipient List
	******************************************************************************/
		
		DECLARE @EmailRecipients VARCHAR(MAX)
		SET @EmailRecipients = (SELECT	CASE
											WHEN @RetailerID = 4846 THEN 'DIProcessCheckers@RewardInsight.com;Matthew.OConnell@RewardInsight.com;Emma.Young@RewardInsight.com'
											ELSE 'Rory.Francis@RewardInsight.com'
										END)

		DECLARE @Separator CHAR(1)
		SET @Separator = CHAR(9)

		EXEC msdb..sp_send_dbmail 
			@profile_name = 'Administrator',
			@recipients= @EmailRecipients,
			@subject = @EmailSubject,
			@execute_query_database = 'Warehouse',
			@query = @FileContents,
			@attach_query_result_as_file = 1,
			@query_attachment_filename=@FileName,
			@query_result_separator= @Separator ,
			@query_result_no_padding=1,
			@query_result_header=0,
			@query_result_width=32767,
			@body= @EmailMessage,
			@body_format = 'HTML', 
			@importance = 'HIGH'

END