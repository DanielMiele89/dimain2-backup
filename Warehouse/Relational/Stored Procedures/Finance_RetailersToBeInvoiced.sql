
/**********************************************************************

	Author:		 
	Create date: 
	Description: 

	======================= Change Log =======================


***********************************************************************/

CREATE PROCEDURE [Relational].[Finance_RetailersToBeInvoiced] (@PreviousTransIncluded INT)

AS
	BEGIN
	SET NOCOUNT ON;

		--	DECLARE @PreviousTransIncluded INT = 1


		/*******************************************************************************************************************************************
			1.	Prepare lookup tables
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#PanToClub') IS NOT NULL DROP TABLE #PanToClub
			SELECT	DISTINCT
					pa.ID AS PanID
				,	fa.ClubID
			INTO #PanToClub
			FROM [SLC_REPL].[dbo].[Pan] pa
			LEFT JOIN [SLC_REPL].[dbo].[Fan] fa
				ON pa.CompositeID = fa.CompositeID
	
			CREATE CLUSTERED INDEX CIX_PanClub ON #PanToClub (PanID, ClubID)		

			IF OBJECT_ID('tempdb..#IssuerBankAccountToClub') IS NOT NULL DROP TABLE #IssuerBankAccountToClub
			SELECT	iba.ID AS IssuerBankAccountID
				,	fa.ClubID
			INTO #IssuerBankAccountToClub
			FROM [SLC_REPL].[dbo].[IssuerBankAccount] iba
			INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic
				ON iba.IssuerCustomerID = ic.ID
			INNER JOIN [SLC_REPL].[dbo].[Fan] fa
				ON ic.SourceUID = fa.SourceUID
				AND ((fa.ClubID = 132 AND IssuerID = 2) OR (fa.ClubID = 138 AND IssuerID = 1))
	
			CREATE CLUSTERED INDEX CIX_PanClub ON #IssuerBankAccountToClub (IssuerBankAccountID, ClubID)

			IF OBJECT_ID('tempdb..#PublisherManagedRetailers') IS NOT NULL DROP TABLE #PublisherManagedRetailers
			SELECT	ClubID
				,	PartnerID
				,	StartDate
				,	ISNULL(EndDate, '9999-12-31') AS EndDate
			INTO #PublisherManagedRetailers
			FROM [SLC_REPL].[dbo].[PublisherManagedRetailers]
	
			CREATE CLUSTERED INDEX CIX_All ON #PublisherManagedRetailers (ClubID, PartnerID, StartDate, EndDate)

		/*******************************************************************************************************************************************
			2.	Fetch raw transactions
		*******************************************************************************************************************************************/

			DECLARE @Today DATETIME = GETDATE()
				,	@MonthStart_1MonthsPrevious DATETIME
				,	@MonthStart_3MonthsPrevious DATETIME

				
			SET @MonthStart_1MonthsPrevious = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today)-1, 0) -- First Day of previous month
			SET @MonthStart_3MonthsPrevious = DATEADD(MONTH, -2, @MonthStart_1MonthsPrevious)
			
			IF OBJECT_ID('tempdb..#TransactionsToInvoice') IS NOT NULL DROP TABLE #TransactionsToInvoice
			SELECT	ro.PartnerID				--	Fetch [SLC_REPL].[dbo].[Match] Transactions for CLO for the most recent month
				,	m.Amount
				,	m.PartnerCommissionAmount
				,	m.vatAmount
				,	m.AddedDate
				,	m.TransactionDate
			INTO #TransactionsToInvoice
			FROM [SLC_REPL].[dbo].[Partner] pa
			INNER JOIN [SLC_REPL].[dbo].[RetailOutlet] ro
				ON pa.ID = ro.PartnerID
			INNER JOIN [SLC_REPL].[dbo].[Match] m
				ON ro.ID = m.RetailOutletID
			LEFT JOIN #PanToClub ptc
				ON ptc.PanID = m.PanID
			WHERE @MonthStart_1MonthsPrevious <= m.AddedDate
			AND m.Status = 1 
			AND m.RewardStatus IN (0, 1) 
			AND m.InvoiceID IS NULL
			AND NOT EXISTS (	SELECT 1	--	Only transactions not covered by a PartnerManagedRetailer entry
								FROM #PublisherManagedRetailers pmr
								WHERE ptc.ClubID = pmr.ClubID
								AND m.TransactionDate >= pmr.StartDate
								AND m.TransactionDate < pmr.EndDate
								AND pmr.PartnerID = ro.PartnerID)

			INSERT INTO #TransactionsToInvoice (PartnerID
											,	Amount
											,	PartnerCommissionAmount
											,	vatAmount
											,	AddedDate
											,	TransactionDate)
			SELECT	iof.PartnerID			--	Fetch [SLC_REPL].[dbo].[Match] Transactions for MFDD for the most recent month
				,	m.Amount
				,	m.PartnerCommissionAmount
				,	m.VatAmount
				,	m.AddedDate
				,	m.TransactionDate
			FROM [SLC_REPL].[dbo].[Partner] pa
			INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
				ON pa.ID = iof.PartnerID
			INNER JOIN [SLC_REPL].[dbo].[DirectDebitOfferOINs] ddoo
				ON iof.ID = ddoo.IronOfferID 
			INNER JOIN [SLC_REPL].[dbo].[Match] m
				ON ddoo.DirectDebitOriginatorID = m.DirectDebitOriginatorID
			LEFT JOIN #IssuerBankAccountToClub itc
				ON itc.IssuerBankAccountID = m.IssuerBankAccountID
			WHERE @MonthStart_1MonthsPrevious <= m.AddedDate
			AND m.Status = 1 
			AND m.RewardStatus IN (0, 1)
			AND m.InvoiceID IS NULL
			AND NOT EXISTS (	SELECT 1	--	Only transactions not covered by a PartnerManagedRetailer entry
								FROM #PublisherManagedRetailers pmr
								WHERE itc.ClubID = pmr.ClubID
								AND m.TransactionDate >= pmr.StartDate
								AND m.TransactionDate < pmr.EndDate
								AND pmr.PartnerID = iof.PartnerID)
						

			INSERT INTO #TransactionsToInvoice (PartnerID
											,	Amount
											,	PartnerCommissionAmount
											,	vatAmount
											,	AddedDate
											,	TransactionDate)
			SELECT	pt.PartnerID				--	Fetch PanLessTrans Transactions for CLO for the most recent month
				,	pt.Price
				,	pt.GrossAmount
				,	pt.VATAmount
				,	pt.AddedDate
				,	pt.TransactionDate
			FROM [SLC_REPL].[RAS].[PANless_Transaction] pt
			WHERE @MonthStart_1MonthsPrevious <= pt.AddedDate
			AND pt.InvoiceID IS NULL




			IF @PreviousTransIncluded = 1
				BEGIN
					INSERT INTO #TransactionsToInvoice
					SELECT	ro.PartnerID
						,	m.Amount
						,	m.PartnerCommissionAmount
						,	m.vatAmount
						,	m.AddedDate
						,	m.TransactionDate
					FROM [SLC_REPL].[dbo].[Partner] pa
					INNER JOIN [SLC_REPL].[dbo].[RetailOutlet] ro
						ON pa.ID = ro.PartnerID
					INNER JOIN [SLC_REPL].[dbo].[Match] m
						ON ro.ID = m.RetailOutletID
					LEFT JOIN #PanToClub ptc
						ON ptc.PanID = m.PanID
					WHERE m.AddedDate < @MonthStart_1MonthsPrevious
					AND @MonthStart_3MonthsPrevious <= m.AddedDate
					AND m.Status = 1 
					AND m.RewardStatus IN (0, 1) 
					AND m.InvoiceID IS NULL
					AND NOT EXISTS (	SELECT 1	--	Only transactions not covered by a PartnerManagedRetailer entry
										FROM #PublisherManagedRetailers pmr
										WHERE ptc.ClubID = pmr.ClubID
										AND m.TransactionDate >= pmr.StartDate
										AND m.TransactionDate < pmr.EndDate
										AND pmr.PartnerID = ro.PartnerID)



					INSERT INTO #TransactionsToInvoice (PartnerID
													,	Amount
													,	PartnerCommissionAmount
													,	vatAmount
													,	AddedDate
													,	TransactionDate)
					SELECT	iof.PartnerID
						,	m.Amount
						,	m.PartnerCommissionAmount
						,	m.VatAmount
						,	m.AddedDate
						,	m.TransactionDate
					FROM [SLC_REPL].[dbo].[Partner] pa
					INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
						ON pa.ID = iof.PartnerID
					INNER JOIN [SLC_REPL].[dbo].[DirectDebitOfferOINs] ddoo
						ON iof.ID = ddoo.IronOfferID 
					INNER JOIN [SLC_REPL].[dbo].[Match] m
						ON ddoo.DirectDebitOriginatorID = m.DirectDebitOriginatorID
					LEFT JOIN #IssuerBankAccountToClub itc
						ON itc.IssuerBankAccountID = m.IssuerBankAccountID
					WHERE m.AddedDate < @MonthStart_1MonthsPrevious
					AND @MonthStart_3MonthsPrevious <= m.AddedDate
					AND m.Status = 1 
					AND m.RewardStatus IN (0, 1) 
					AND m.InvoiceID IS NULL
					AND NOT EXISTS (	SELECT 1	--	Only transactions not covered by a PartnerManagedRetailer entry
										FROM #PublisherManagedRetailers pmr
										WHERE itc.ClubID = pmr.ClubID
										AND m.TransactionDate >= pmr.StartDate
										AND m.TransactionDate < pmr.EndDate
										AND pmr.PartnerID = iof.PartnerID)
						

					INSERT INTO #TransactionsToInvoice (PartnerID
													,	Amount
													,	PartnerCommissionAmount
													,	vatAmount
													,	AddedDate
													,	TransactionDate)
					SELECT	pt.PartnerID
						,	pt.Price
						,	pt.GrossAmount
						,	pt.VATAmount
						,	pt.AddedDate
						,	pt.TransactionDate
					FROM [SLC_REPL].[RAS].[PANless_Transaction] pt
					WHERE pt.AddedDate < @MonthStart_1MonthsPrevious
					AND @MonthStart_3MonthsPrevious <= pt.AddedDate
					AND pt.InvoiceID IS NULL


				END
		
			CREATE CLUSTERED INDEX CIX_PartnerID ON #TransactionsToInvoice (PartnerID)


		/*******************************************************************************************************************************************
			3.	Aggregate to retailer level
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..##TransactionsToInvoice_Agg') IS NOT NULL DROP TABLE ##TransactionsToInvoice_Agg
			SELECT	COALESCE(pri.PrimaryPartnerID, tti.PartnerID) AS PartnerID
				,	pa.Name AS PartnerName
				,	ISNULL(CONVERT(decimal(24,2), SUM(tti.Amount)),0.00) as Price
				,	ISNULL(CONVERT(decimal(24,2), SUM(tti.PartnerCommissionAmount)), 0.00) as GrossAmount
				,	ISNULL(CONVERT(decimal(24,2), SUM(tti.VatAmount)),0.00) as VatAmount
				,	ISNULL(CONVERT(decimal(24,2), SUM(tti.PartnerCommissionAmount) - SUM(tti.VatAmount)), 0.00) as NetAmount
				,	MIN(tti.AddedDate) AS FistAdded
				,	MAX(tti.AddedDate) AS LastAdded
				,	MIN(tti.TransactionDate) AS FistTransactionDate
				,	MAX(tti.TransactionDate) AS LastTransactionDate
			INTO ##TransactionsToInvoice_Agg
			FROM #TransactionsToInvoice tti
			LEFT JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
				ON tti.PartnerID = pri.PartnerID
			LEFT JOIN [SLC_REPL].[dbo].[Partner] pa
				ON COALESCE(pri.PrimaryPartnerID, tti.PartnerID) = pa.ID
			GROUP BY	COALESCE(pri.PrimaryPartnerID, tti.PartnerID)
					,	pa.Name

			CREATE CLUSTERED INDEX CIX_PartnerName ON ##TransactionsToInvoice_Agg (PartnerName)


		/*******************************************************************************************************************************************
			4.	Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				4.1. Declare User Variables
			***********************************************************************************************************************/

				DECLARE	@Style VarChar(Max)
					,	@Subject VarChar(Max)
					,	@Regards VarChar(Max)
					,	@Body VarChar(Max)
					,	@ExcelInvoiceList VarChar(Max)
					,	@AttachNameInvoiceList VarChar(Max)
			  

			/***********************************************************************************************************************
				4.2. Set email HTML style
			***********************************************************************************************************************/

				SET @Style = 
				'<style>
					table {border-collapse: collapse;}

					p {font-family: Calibri;}
	
					th {padding: 10px;}
	
					table, td {padding: 0 10 0 10;}
	
					table, td, th {border: 1px solid black;
								   font-family: Calibri;}
				</style>'
			  

			/***********************************************************************************************************************
				4.3. Set email subject
			***********************************************************************************************************************/

				SET @Subject = 'Retailers To Be Invoiced ' + FORMAT(@MonthStart_1MonthsPrevious, 'Y')
			  

			/***********************************************************************************************************************
				4.4. Set email message
			***********************************************************************************************************************/

				SET @Body = 
				'Hi there,<br><br>Please see attached a file containing all of the retailers that have had a transactions processed in the last calendar month and are due to be invoiced.'

				IF @PreviousTransIncluded = 1 SET @Body = @Body + '<br><br>We have also included all historic transactions that have not yet been invoiced.'
			  

			/***********************************************************************************************************************
				4.5. Set email sign off
			***********************************************************************************************************************/

				SET @Regards = 'Regards,<br>Data Ops'


		/*******************************************************************************************************************************************
			5. Combine variables to form email body
		*******************************************************************************************************************************************/

			SET @Body = @Style + @Body + '<br><br>' + @Regards


		/*******************************************************************************************************************************************
			6. Prepare exclusions file to attach to email
		*******************************************************************************************************************************************/

			SET @ExcelInvoiceList = '
				SET NOCOUNT ON;

				SELECT ''sep=;' + Char(13) + Char(10) + 
						'Partner Name''
					,	''Price''
					,	''Gross Amount''
					,	''Vat Amount''
					,	''Net Amount''
					,	''Fist Processed Date''
					,	''Last Processed Date''
					,	''Fist Transaction Date''
					,	''Last Transaction Date''

				UNION ALL

				SELECT	PartnerName
					,	CONVERT(VARCHAR, Price)
					,	CONVERT(VARCHAR, GrossAmount)
					,	CONVERT(VARCHAR, VatAmount)
					,	CONVERT(VARCHAR, NetAmount)
					,	CONVERT(VARCHAR, FistAdded)
					,	CONVERT(VARCHAR, LastAdded)
					,	CONVERT(VARCHAR, FistTransactionDate)
					,	CONVERT(VARCHAR, LastTransactionDate)
				FROM ##TransactionsToInvoice_Agg' 

			SET @AttachNameInvoiceList = 'Retailers To Be Invoiced ' + FORMAT(@MonthStart_1MonthsPrevious, 'Y') + '.csv'


		/*******************************************************************************************************************************************
			7. Send email
		*******************************************************************************************************************************************/

			EXEC [msdb].[dbo].[sp_send_dbmail]	@profile_name = 'Administrator'
											,	@recipients= 'Andrew.Morrison@RewardInsight.com;DataOperations@RewardInsight.com'
											,	@subject = @Subject
											,	@execute_query_database = 'Warehouse'
											,	@query = @ExcelInvoiceList
											,	@attach_query_result_as_file = 1
											,	@query_attachment_filename = @AttachNameInvoiceList
											,	@query_result_separator=';'
											,	@query_result_no_padding=1
											,	@query_result_header=0
											,	@query_result_width=32767
											,	@body= @body
											,	@body_format = 'HTML'
											,	@importance = 'HIGH'

			DROP TABLE ##TransactionsToInvoice_Agg

	END