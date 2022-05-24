
create procedure smartemail.TriggerEmail_Welcome_Retrospective @Date date
as 
begin


--DECLARE @DATE DATE = '20201010' --'20201013'
	
	Declare @msg VARCHAR(2048)
		,@time DATETIME


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
			AND (P.RemovalDate IS NULL OR DATEDIFF(D, P.RemovalDate, @Date) <= 14)
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

		DECLARE @ReportDate DATE = CAST(DATEADD(dd, -1, @date) AS DATE);

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

		DECLARE @ActivatedDate DATE = DATEADD(dd, -2, @date)

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




	--INSERT FINAL DATA
	Insert Into SmartEmail.TriggerEmail_WelcomeEmailCode_Retrospective
	Select FanID, WelcomeEmailCode
	From #Fans
	Where WelcomeEmailCode is not NULL

END 


