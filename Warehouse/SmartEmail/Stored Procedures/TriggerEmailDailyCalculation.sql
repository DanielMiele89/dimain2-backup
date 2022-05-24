

CREATE PROCEDURE [SmartEmail].[TriggerEmailDailyCalculation] 
--WITH EXECUTE AS OWNER 
AS 
BEGIN

-- ********************************************************************************************************************UPDATE ME 

/********************************************************************************************
	Name: SmartEmail.TriggerEmailDailyCalculation
	Desc: Create the values for the daily file that creates the values for the trigger emails
	Auth: Zoe Taylor

	Change History
			ZT 17/05/2018 - Stored procedure created
20180525 cjm changed 3-part name to 2-part name				
	
*********************************************************************************************/
	DECLARE @DATE DATE = GETDATE()
	Declare @msg VARCHAR(2048),@time DATETIME


	/******************************************************************		
			Calc Nominee Changes 
	******************************************************************/

		--
		--Exec Staging.[SLC_Report_DailyLoad_CBP_ProcessDirectDebitStats_SFD]
		--Exec Staging.SLC_Report_DailyLoad_NomineeChangeUpdate


	/******************************************************************		
			Get full list of customers and calc Debit/Credit
	******************************************************************/

		IF OBJECT_ID('tempdb..#Fans') IS NOT NULL DROP TABLE #Fans
		CREATE TABLE #FANS (FanID INT NOT NULL
						  , CompositeID BIGINT NOT NULL 
						  , SourceUID VARCHAR(50) NULL
						  , ClubID INT NOT NULL
						  , ActivatedDate DATETIME NOT NULL
						  , LoyaltyAccount INT NULL
						  , IsLoyalty INT NULL
						  , IsCredit INT NULL
						  , IsDebit INT NULL
						  , ClubCashAvailable MONEY NULL
						  , ClubCashPending MONEY NULL
						  , Postcode VARCHAR(10) NULL
						  , Homemover INT NULL
						  , WelcomeEmailCode VARCHAR(10) NULL
						  , DateOfLastCard DATETIME NULL
						  , MyRewardAccount VARCHAR(50) NULL)

		INSERT INTO #Fans (FanID
						 , CompositeiD
						 , SourceUID
						 , ClubID
						 , ActivatedDate
						 , LoyaltyAccount
						 , IsLoyalty
						 , IsCredit
						 , IsDebit
						 , ClubCashAvailable
						 , ClubCashPending
						 , Postcode
						 , Homemover
						 , WelcomeEmailCode)
		SELECT f.ID AS FanID
			 , f.CompositeID
			 , SourceUID
			 , ClubID
			 , AgreedTCsDate AS ActivatedDate
			 , 0 AS LoyaltyAccount
			 , 0 AS IsLoyalty
			 , ISNULL(MAX(CASE
							WHEN PC.CardTypeID = 1 THEN 1
							ELSE 0
						  END) , 0) AS IsCredit
			 , ISNULL(MAX(CASE
							WHEN BO.FanID IS NOT NULL THEN 0
							WHEN PC.CardTypeID = 2 THEN 1
							ELSE 0
						  END), 0) AS IsDebit
			 , ClubCashAvailable
			 , ClubCashPending		
			 , f.Postcode
			 , 0 Homemover
			 , NULL AS WelcomeEmailCode
		FROM [SLC_Report].[dbo].[Fan] f WITH (NOLOCK)
		LEFT JOIN [SLC_Report].[dbo].[Pan] p WITH (NOLOCK) 
			ON p.CompositeID = f.CompositeID
			AND (P.RemovalDate IS NULL OR DATEDIFF(D, P.RemovalDate, @DATE) <= 14)
		LEFT JOIN [SLC_Report].[dbo].[PaymentCard] pc WITH (NOLOCK) 
			ON p.PaymentCardID = PC.ID
		LEFT JOIN [SLC_Report].[dbo].[BankProductOptOuts] bo WITH (NOLOCK) 
			ON p.UserID = BO.FanID
			AND BO.BankProductID = 1 
			AND BO.OptOutDate IS NOT NULL 
			AND BO.OptBackInDate IS NULL
		WHERE f.ClubID IN (132, 138)
		AND f.AgreedTCsDate IS NOT NULL
		AND f.[Status] = 1
		AND f.DeceasedDate IS NULL
		GROUP BY f.CompositeID
			   , f.ID
			   , f.SourceUID
			   , f.ClubID
			   , f.AgreedTCSDate
			   , ClubCashAvailable
			   , ClubCashPending
			   , f.Postcode

		CREATE CLUSTERED INDEX F_ID ON #Fans(FanID)

	/******************************************************************		
			Find Loyalty Customers and set Loyalty flags 
	******************************************************************/

		UPDATE fa
		SET IsLoyalty = 1
		FROM #Fans fa
		WHERE EXISTS (	SELECT 1
						FROM [SLC_Report].[dbo].[IssuerCustomer] ic
						INNER JOIN [SLC_Report].[dbo].[IssuerCustomerAttribute] ica
							ON ic.ID = ica.IssuerCustomerID
						WHERE ica.[Value] LIKE '%V%'
						AND ica.EndDate IS NULL
						AND fa.SourceUID = ic.SourceUID
						AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381))

	/******************************************************************		
			Calc Welcomes 
			- Calculates the Welcome code for a customer
			- W7 = Adding CC
			- W8 = CC Only
	******************************************************************/
	

/*	Removed For Reward 3.0 CC Welcome Update: 2019-01-17

		IF OBJECT_ID('tempdb..#WelcomeMembers') IS NOT NULL DROP TABLE #WelcomeMembers
		CREATE TABLE #WelcomeMembers (
				FanID INT NOT NULL PRIMARY KEY,
				RowNumber INT NOT NULL,
				NewCreditCardToday BIT NULL,
				HasCreditCardBefore BIT NULL,
				NewDebitCardToday BIT NULL,
				HasDebitCardBefore BIT NULL,
				ActivatedBeforeToday BIT NULL,
				LastAddedCard DATETIME NULL,
				WelcomeCode AS 
					CASE 
						WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 1 THEN 'W1'
						WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 0 THEN 'W2'
						WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 THEN 'W3'
						WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 0 AND HasDebitCardBefore = 0 THEN 'W4'
						WHEN NewCreditCardToday = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 AND HasCreditCardBefore = 1 THEN 'W5'
					END
			)	

			DECLARE @ReportDate DATE = CAST(DATEADD(dd, -1, GETDATE()) AS DATE);

			;WITH Members AS (
				SELECT 
					F.FanID AS FanID,			
					(CASE WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1 ELSE 0 END) AS NewCreditCardToday,
					(CASE WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1 ELSE 0 END) AS HasCreditCardBefore,
					(CASE WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1 ELSE 0 END) AS NewDebitCardToday,
					(CASE WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1 ELSE 0 END) AS HasDebitCardBefore,
					(CASE WHEN CONVERT(DATE, F.ActivatedDate) < @ReportDate THEN 1 ELSE 0 END) AS ActivatedBeforeToday,
					P.AdditionDate
				FROM #Fans AS F WITH (NOLOCK)
				INNER JOIN SLC_Report.dbo.Pan AS P WITH (NOLOCK) 
					ON P.CompositeID = F.CompositeID
				INNER JOIN SLC_Report.dbo.PaymentCard AS PC WITH (NOLOCK) 
					ON P.PaymentCardID = PC.ID
			)
			INSERT INTO #WelcomeMembers(
				FanID,
				RowNumber,
				NewCreditCardToday,
				HasCreditCardBefore,
				NewDebitCardToday,
				HasDebitCardBefore,
				ActivatedBeforeToday,
				LastAddedCard)
			SELECT FanID,
				ROW_NUMBER() OVER (ORDER BY FanID ) AS RowNumber,
				MAX(NewCreditCardToday) AS NewCreditCardToday,
				MAX(HasCreditCardBefore) AS HasCreditCardBefore,
				MAX(NewDebitCardToday) AS NewDebitCardToday,
				MAX(HasDebitCardBefore) AS HasDebitCardBefore,
				MAX(ActivatedBeforeToday) AS ActivatedBeforeToday,
				MAX(AdditionDate)
			FROM Members
			GROUP BY FanID;

			UPDATE F 
				SET WelcomeEmailCode = (Case
										When w.WelcomeCode = 'W4' and ActivatedDate >= CAST(DATEADD(dd, -2, GETDATE()) AS DATE) then 'W8'
										When w.WelcomeCode in ('W1','w2','w3','W4') then 'W7'
										Else w.WelcomeCode
									End)  
				, DateOfLastCard = convert(date, w.LastAddedCard)
			FROM #Fans AS F
			INNER JOIN #WelcomeMembers AS W 
				ON F.FanID = W.FanID

*/

		IF OBJECT_ID('tempdb..#WelcomeMembers') IS NOT NULL DROP TABLE #WelcomeMembers
		CREATE TABLE #WelcomeMembers (FanID INT NOT NULL PRIMARY KEY
									, RowNumber INT NOT NULL
									, NewCreditCardToday BIT NULL
									, HasCreditCardBefore BIT NULL
									, NewDebitCardToday BIT NULL
									, HasDebitCardBefore BIT NULL
									, ActivatedBeforeToday BIT NULL
									, LastAddedCard DATETIME NULL
									, CreditProductType VARCHAR(25)
									, WelcomeCode AS	CASE 
															WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 1 THEN 'W1'
															WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 0 THEN 'W2'
															WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 THEN 'W3'
															WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 0 AND HasDebitCardBefore = 0 THEN 'W4'
															WHEN NewCreditCardToday = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 AND HasCreditCardBefore = 1 THEN 'W5'
														END)	

		DECLARE @ReportDate DATE = CAST(DATEADD(dd, -1, @DATE) AS DATE);

		;WITH
		Members AS (SELECT fa.FanID
						 , CASE
								WHEN pc.CardTypeID = 1 AND CONVERT(DATE, pa.AdditionDate) =  @ReportDate AND pa.RemovalDate IS NULL THEN 1 ELSE 0
						   END AS NewCreditCardToday
						 , CASE
								WHEN pc.CardTypeID = 1 AND CONVERT(DATE, pa.AdditionDate) <  @ReportDate THEN 1 ELSE 0 
						   END AS HasCreditCardBefore
						 , CASE
								WHEN pc.CardTypeID = 2 AND CONVERT(DATE, pa.AdditionDate) =  @ReportDate AND pa.RemovalDate IS NULL THEN 1 ELSE 0 
						   END AS NewDebitCardToday
						 , CASE
								WHEN pc.CardTypeID = 2 AND CONVERT(DATE, pa.AdditionDate) <  @ReportDate THEN 1 ELSE 0 
						   END AS HasDebitCardBefore
						 , CASE
								WHEN CONVERT(DATE, fa.ActivatedDate) < @ReportDate THEN 1 ELSE 0 
						   END AS ActivatedBeforeToday
						 , pa.AdditionDate
						 , pt.Name AS CreditProductType
					FROM #Fans fa
					INNER JOIN [SLC_Report].[dbo].[Pan] pa
					   ON fa.CompositeID = pa.CompositeID
					INNER JOIN [SLC_Report].[dbo].[PaymentCard] pc
					   ON pa.PaymentCardID = pc.ID
					LEFT JOIN [SLC_Report].[dbo].[PaymentCardProductType] pcpt
						ON pc.ID = pcpt.PaymentCardID
					LEFT JOIN [SLC_Report].[dbo].[CBP_Credit_ProductType] pt
						ON pcpt.ProductTypeID = pt.ID)

		INSERT INTO #WelcomeMembers (FanID
								   , RowNumber
								   , NewCreditCardToday
								   , HasCreditCardBefore
								   , NewDebitCardToday
								   , HasDebitCardBefore
								   , ActivatedBeforeToday
								   , LastAddedCard
								   , CreditProductType)
		SELECT FanID
			 , ROW_NUMBER() OVER (ORDER BY FanID) AS RowNumber
			 , MAX(NewCreditCardToday) AS NewCreditCardToday
			 , MAX(HasCreditCardBefore) AS HasCreditCardBefore
			 , MAX(NewDebitCardToday) AS NewDebitCardToday
			 , MAX(HasDebitCardBefore) AS HasDebitCardBefore
			 , MAX(ActivatedBeforeToday) AS ActivatedBeforeToday
			 , MAX(AdditionDate) AS LastAddedCard
			 , MAX(CreditProductType) AS CreditProductType
		FROM Members
		GROUP BY FanID

		DECLARE @ActivatedDate DATE = DATEADD(dd, -2, @DATE)

		UPDATE fa
		SET WelcomeEmailCode = (Case
									When wm.WelcomeCode = 'W4' and ActivatedDate >= @ActivatedDate AND wm.CreditProductType = 'Reward Credit' then 'W8'
									When wm.WelcomeCode = 'W4' and ActivatedDate >= @ActivatedDate AND wm.CreditProductType = 'Reward Black Credit' then 'W8-RB'
									When wm.WelcomeCode in ('W1','w2','w3','W4') AND wm.CreditProductType = 'Reward Credit' then 'W7'
									When wm.WelcomeCode in ('W1','w2','w3','W4') AND wm.CreditProductType = 'Reward Black Credit' then 'W7-RB'
									Else wm.WelcomeCode
								End)  
		  , DateOfLastCard = CONVERT(DATE, wm.LastAddedCard)
		FROM #Fans fa
		INNER JOIN #WelcomeMembers wm
			ON fa.FanID = wm.FanID

	/******************************************************************		
			 Calc Homemovers
			 -- Calculates the customers that have moved home
	******************************************************************/

		UPDATE fa
		SET fa.Homemover = 1 
		FROM #Fans fa
		INNER JOIN [Relational].[Customer] cu
			ON fa.FanID = cu.FanID
		WHERE LEFT(REPLACE(cu.Postcode,' ',''), 6) != LEFT(REPLACE(fa.Postcode,' ',''), 6) 
		AND LEN(cu.postcode) >= 5 
		AND LEN(fa.Postcode) >= 5
		AND 1 = 2	-- RF 20191114 

	/******************************************************************		
			Calc Reached 5GBP 
			-- Calculates those that have reached £5 cashback available
			-- Updated Redeem flag for Redemption Reminder emails
	******************************************************************/	
	
		DECLARE @Reach5GBPToday DATE = GETDATE()

		INSERT INTO [Relational].[Customers_Reach5GBP]
		SELECT fa.FanID AS FanID
			 , @Reach5GBPToday AS Reached
			 , 0 AS Redeemed
		FROM #Fans fa
		WHERE fa.ClubCashAvailable > 5
		AND NOT EXISTS (SELECT 1
						FROM [Relational].[Customers_Reach5GBP] cr5
						WHERE fa.FanID = cr5.FanID)

		/*----------------------------------------------------------------		
		   		Find those that have redeemed and update flag 
				-- Redemption Reminder flag      
		------------------------------------------------------------------*/		

			IF OBJECT_ID('tempdb..#Customers_Reach5GBP') IS NOT NULL DROP TABLE #Customers_Reach5GBP
			SELECT DISTINCT
				   tr.FanID
			INTO #Customers_Reach5GBP
			FROM [SLC_Report].[dbo].[Trans] tr
			INNER JOIN [SLC_Report].[dbo].[RedeemAction] ra
				ON tr.ID = ra.TransID
				AND ra.Status IN (1, 6)
			WHERE tr.TypeID = 3
			AND tr.Points > 0
			AND EXISTS (SELECT 1
						FROM [SLC_Report].[dbo].[Redeem] re
						WHERE re.ID = tr.ItemID)
			AND EXISTS (SELECT 1
						FROM [Relational].[Customers_Reach5GBP] cr5
						WHERE tr.FanID = cr5.FanID
						AND Redeemed = 0)
			
			UPDATE cr5
			SET cr5.Redeemed = 1
			FROM [Relational].[Customers_Reach5GBP] cr5
			WHERE cr5.Redeemed = 0
			AND EXISTS (SELECT 1
						FROM #Customers_Reach5GBP c
						WHERE cr5.FanID = c.FanID)


	/******************************************************************		
			Calc FirstEarn 
			-- Calculates when someone has earned for the first time 
	******************************************************************/	

		TRUNCATE TABLE [SmartEmail].[TriggerEmailDailyFile_FirstEarn_Calculation]
		INSERT INTO [SmartEmail].[TriggerEmailDailyFile_FirstEarn_Calculation]
		SELECT FanID
		FROM #Fans
		WHERE LoyaltyAccount = 1

		Exec Staging.SLC_Report_DailyLoad_FirstSpend
		Exec Staging.SLC_Report_DailyLoad_LoyaltyPhase2V1_2
	
		Update f
		Set LoyaltyAccount = Case
								When l.FanID is null then 0
							Else 1 
						End
		From #Fans f
		Left Outer join Staging.LoyaltyPhase2Customers as l
			on	f.FanID = l.FanID

				
		/*----------------------------------------------------------------		
				  Earned on DD Offer
		------------------------------------------------------------------*/
		if object_id('tempdb..#FirstEarnDD') is not null drop table #FirstEarnDD
		Select * 
		Into #FirstEarnDD
		from
		(
			Select * ,
					ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
			from Staging.Customer_FirstEarnDDPhase2 as a
			Where a.FirstEarnDate = DATEADD(dd, -1, DATEDIFF(dd, 0, @DATE))
		) as a
		Where RowNo = 1
		AND 1 = 2	-- RF 20191114 

		/*----------------------------------------------------------------		
				  Pull through Not Earned on MY Rewards DD 
		------------------------------------------------------------------*/
		if object_id('tempdb..#NotEarned') is not null drop table #NotEarned


		Select FanID,
				AccountNo as Day65AccountNo,
				Replace(a.AccountName,' account','') as Day65AccountName
		Into #NotEarned
		from
		(
		Select *,
				ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
		from Staging.Customer_DDNotEarned
		Where ChangeDate = DATEADD(dd, -65, DATEDIFF(dd, 0, @Date))
		) as a
		Where RowNo = 1
	
		/*----------------------------------------------------------------		
				 First Earn POS Calc
		------------------------------------------------------------------*/	
		if object_id('tempdb..#FirstEarn') is not null drop table #FirstEarn

		Select a.FanID,
				a.FirstEarnValue,
				a.FirstEarnType
		Into #FirstEarn
		from Staging.Customers_Passed0GBP as a
		Left Outer join Staging.Customer_FirstEarnDDPhase2 as b
			on a.fanid = b.fanID
		Where	b.FanID is null and
				a.[Date] = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
		and len(FirstEarnType) > 0

		Update F
		Set MyRewardAccount = fedd.AccountName 
		from #Fans f
		Inner Join #FirstEarnDD fedd
			on fedd.FanID = f.FanID

	/******************************************************************		
			Build LoyaltyPhase2 Tables
	******************************************************************/

	Truncate Table Staging.SLC_Report_DailyLoad_Phase2DataFields

	Insert into Staging.SLC_Report_DailyLoad_Phase2DataFields (FanID, IsLoyalty, LoyaltyAccount, MyRewardAccount)
	Select FanID,IsLoyalty, LoyaltyAccount , ''
	From #FANS
	
	Exec Staging.SLC_Report_Update_FanSFDDailyUploadData_DirectDebit


	/******************************************************************		
			Calc Product Monitoring 
			-- Calculates 60 day and 120 day product monitoring values
	******************************************************************/
		--Exec Staging.SLC_Report_DailyLoad_DirectDebit60days_2_0
		--Exec Staging.SLC_Report_DailyLoad_DirectDebit120days_2_0

		EXEC [SmartEmail].[TriggerEmail_ProductMonitoring] 65
		EXEC [SmartEmail].[TriggerEmail_ProductMonitoring] 125

		IF (SELECT CONVERT(DATE, GETDATE())) = '2020-07-15' EXEC [SmartEmail].[TriggerEmail_ProductMonitoringMopUp_20200712]

			/*----------------------------------------------------------------		
					  Get list of bank account names for customers
			------------------------------------------------------------------*/		
			if object_id('tempdb..#BankAccounts_ProdMon') is not null drop table #BankAccounts_ProdMon
			Select a.FanID,AccountName1
			Into #BankAccounts_ProdMon
			From slc_report.dbo.FanSFDDailyUploadData_DirectDebit as a
			inner join #Fans as b
				on a.FanID = b.FanID
			Where	b.LoyaltyAccount = 1 and
					b.MyRewardAccount = '' and
					a.AccountName1 like 'Reward%'
			Union All
			Select a.FanID,AccountName2
			From slc_report.dbo.FanSFDDailyUploadData_DirectDebit as a
			inner join #Fans as b
				on a.FanID = b.FanID
			Where	b.LoyaltyAccount = 1 and
					b.MyRewardAccount = '' and
					a.AccountName2 like 'Reward%'
			Union All
			Select a.FanID,AccountName3
			From slc_report.dbo.FanSFDDailyUploadData_DirectDebit as a
			inner join #Fans as b
				on a.FanID = b.FanID
			Where	b.LoyaltyAccount = 1 and
					b.MyRewardAccount = '' and
					a.AccountName3 like 'Reward%'

			/*----------------------------------------------------------------		
					Pick highest ranked account 
			------------------------------------------------------------------*/
			if object_id('tempdb..#BankAccounts_Distinct') is not null drop table #BankAccounts_Distinct

			Select	a.FanID,
					Replace(a.AccountName1,' Account','') as MyRewardAccount 
			Into #BankAccounts_Distinct
			From
			(
			Select	a.*,
					ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Case
																		When AccountName1 like '%Black%' then 0
																		When AccountName1 like '%Plat%' then 1
																		When AccountName1 like '%Silver%' then 2
																		When AccountName1 like '%Reward%' then 3
																		Else 4
																	End ASC) AS RowNo
			from #BankAccounts_ProdMon as a
			) as a
			Where	a.RowNo = 1

			/*----------------------------------------------------------------		
					Update MyRewardAccount name field
			------------------------------------------------------------------*/
			
			Update b
			Set b.MyRewardAccount = a.MyRewardAccount
			From #Fans as b with (Nolock)
			inner join  #BankAccounts_Distinct as a
				on a.FanID = b.FanID
			Where Len(b.MyRewardAccount) = 0

	/******************************************************************		
					Calculate W&G Customer list for exclusion 
	******************************************************************/
			/*----------------------------------------------------------------		
					Find all accounts that are Williams & Glynn
			------------------------------------------------------------------*/
			if object_id('tempdb..#BankAccounts') is not null drop table #BankAccounts

			Select	BankAccountID,
					ROW_NUMBER() OVER(ORDER BY BankAccountID Asc) AS RowNo
			Into #BankAccounts
			From 
			(
			Select Distinct ba.ID as BankAccountID
			from Staging.WG_SortCodes as sc with (nolock)
			inner join SLC_Report.dbo.bankaccount as ba with (nolock)
				on	sc.Sortcode = ba.SortCode and
					COALESCE(BA.[Status], 1) = 1
			) as a

			Create Clustered index ix_BankAccounts_BAID on #BankAccounts (BankAccountID)
			
			/*----------------------------------------------------------------		
					Find W&G customers for exclusion
			------------------------------------------------------------------*/	
			if object_id('tempdb..#CustomersWG') is not null drop table #CustomersWG

			Select distinct 
					f.Fanid
					, 1 as WG
			Into #CustomersWG
			from #BankAccounts as ba
			inner join SLC_Report.[dbo].[IssuerBankAccount] as iba with (nolock)
				on	BA.BankAccountID  = IBA.BankAccountID and
					COALESCE(IBA.CustomerStatus, 1) = 1
			inner join SLC_Report.[dbo].IssuerCustomer as ic with (nolock)
				on	iba.IssuerCustomerID = ic.id
			inner join #Fans as f with (nolock)
				on  ic.SourceUID = f.sourceuid and
					ic.IssuerID = (Case when ClubID = 132 then 2 else 1 end)

	/******************************************************************		
			Final data set 
	******************************************************************/
		Truncate Table SmartEmail.TriggerEmailDailyFile_Calculated

		Insert Into SmartEmail.TriggerEmailDailyFile_Calculated 
				(FanID, LoyaltyAccount, IsLoyalty, IsDebit, IsCredit, WG, FirstEarnDate, FirstEarnType, FirstEarnValue, Reached5GBP, Day65AccountName, Day65AccountNo, MyRewardAccount, Homemover, WelcomeEmailCode)
		Select 
			f.FanID
			, f.LoyaltyAccount
			, f.IsLoyalty
			, f.IsDebit
			, f.IsCredit
			, COALESCE(wg.WG, 0) as WG
			, Case
					When fe.FirstEarnDate is not null then fe.FirstEarnDate
					When fe2.FanID is not null then DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
					Else '1900-01-01' 
				End as FirstEarnDate
			, Case when fe.FanID is not null then 'direct debit frontbook'
					 Else Coalesce(fe2.FirstEarnType,'')
				End as FirstEarnType
			, coalesce(fe.FirstEarnValue,fe2.FirstEarnValue,0) as FirstEarnValue
			, coalesce(Reached,'1900-01-01') as Reached5GBP
			, Coalesce(ne.Day65AccountName,'') as Day65AccountName
			, Coalesce(ne.Day65AccountNo,'') as Day65AccountNo
			, Coalesce(fe.AccountName,'') as MyRewardAccount	
			, f.Homemover
			, f.WelcomeEmailCode
		From #Fans f
		left outer join #CustomersWG as wg
			on	f.FanID = WG.FanID
		left outer join Staging.Customers_Passed0GBP as a
			on	f.FanID = a.FanID and
				a.Date = @Date
		Left Outer join #FirstEarnDD as fe
			on	f.FanID = fe.FanID
		Left Outer join #FirstEarn as fe2
			on f.FanID = fe2.FanID
		Left Outer join [Relational].[Customers_Reach5GBP] as g5
			on	f.FanID = g5.FanID and
				g5.Redeemed = 0
		Left Outer join #NotEarned as ne
			on	f.FanID = ne.FanID


END
---------------------------------------------------------------------------------------------------------------------------------------------