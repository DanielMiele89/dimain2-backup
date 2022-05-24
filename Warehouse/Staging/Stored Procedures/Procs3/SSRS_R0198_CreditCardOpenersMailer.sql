/*
	Author:			Stuart Barnley

	Date:			17-11-2015

	Purpose:		To provide a list of customers who have opened a MyRewards credit
					card, this is sent to a mailhouse so they can be sent the 
					introductory information.

	Updates:		N/A


*/
CREATE PROCEDURE [Staging].[SSRS_R0198_CreditCardOpenersMailer]
AS
	BEGIN

		----------------------------------------------------------------------------------
		-------------------- Declare variables for the report to use ---------------------
		----------------------------------------------------------------------------------

			Declare @Date Date = GetDate()
				  , @Startdate Date			-- Is used to hold the date the cards should have been added from
				  , @EndDate Date			-- Is used to hold the date the cards should have been added by
				  , @TableName VarChar(300)	-- This is the name of the new data table that will be created
				  , @Qry nVarChar(500)		-- This is used to hold any query that needs to be generated then run

		----------------------------------------------------------------------------------
		-------------Use todays date to go back and select customers ---------------------
		----------------------------------------------------------------------------------

			Set DateFirst 1
			Set @StartDate = DateAdd(day, -11, (Select [Staging].[fnGetStartOfWeek](@Date)))
			Set @EndDate = DateAdd(day, 6, @StartDate)

		----------------------------------------------------------------------------------
		-------------- Select the customers that need to be contacted --------------------
		----------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#ExistingCreditCardOpeners') IS NOT NULL DROP TABLE #ExistingCreditCardOpeners
			Select FanID
			Into #ExistingCreditCardOpeners
			From Staging.CreditCardOpeners
			Where SendDate > DateAdd(day, -35, @Date)

			CREATE CLUSTERED INDEX CIX_ExistingCreditCardOpeners_FanID On #ExistingCreditCardOpeners (FanID)

			IF OBJECT_ID('tempdb..#NewCreditCardOpeners') IS NOT NULL DROP TABLE #NewCreditCardOpeners
			Select pa.UserID
				 , Convert(Date, pc.Date) as Date
			Into #NewCreditCardOpeners
			From SLC_Report.dbo.Pan pa With (NoLock) 
			Inner join SLC_Report.dbo.PaymentCard pc
				on	pa.PaymentCardID = pc.ID
			Where pa.AffiliateID = 1 
			And pc.CardTypeID = 1
			And Convert(Date, pa.AdditionDate) Between @StartDate and @EndDate
			And pc.Date = AdditionDate
			And pa.RemovalDate is null
			And Not Exists (Select 1
							From #ExistingCreditCardOpeners cco
							Where pa.UserID = cco.FanID)

			CREATE CLUSTERED INDEX CIX_NewCreditCardOpeners_UserID On #NewCreditCardOpeners (UserID)
			Set @EndDate = DateAdd(day, 6, @StartDate)

		----------------------------------------------------------------------------------
		---------------------- Fetch the selected customers details ----------------------
		----------------------------------------------------------------------------------
		
			IF OBJECT_ID('tempdb..#AllCustomer') IS NOT NULL DROP TABLE #AllCustomer
			SELECT *
			INTO #AllCustomer
			FROM Relational.Customer cu
			WHERE EXISTS (	SELECT 1
							FROM #NewCreditCardOpeners cco
							WHERE cu.FanID = cco.UserID)
			And cu.CurrentlyActive = 1
			And Len(cu.FirstName) > 1
			And Len(cu.Lastname) > 1
			And (cu.EmailStructureValid = 0 or cu.ActivatedOffline = 1)
			
			CREATE CLUSTERED INDEX CIX_FanID ON #AllCustomer (FanID)
		
			IF OBJECT_ID('tempdb..#Customer_RBSGSegments') IS NOT NULL DROP TABLE #Customer_RBSGSegments
			SELECT *
			INTO #Customer_RBSGSegments
			FROM Relational.Customer_RBSGSegments rbs
			WHERE EXISTS (	SELECT 1
							FROM #AllCustomer cu
							WHERE rbs.FanID = cu.FanID)
			AND rbs.EndDate IS NULL
			
			CREATE CLUSTERED INDEX CIX_FanID ON #Customer_RBSGSegments (FanID)
			
			IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
			Select cu.FanID as CustomerID
				 , Case
						When cu.ClubID = 132 then 'NatWest'
						When cu.ClubID = 138 then 'RBS'
				   End as Brand
				 , MAX(	Case
							When rbs.CustomerSegment Is Null Then 'N' -- Core
							When rbs.CustomerSegment = 'V' Then 'Y'   -- Private
							Else 'N'
						End) as [Private]
				 , LTrim(RTrim(cu.Title)) as Title
				 , LTrim(RTrim(cu.Firstname)) as Firstname
				 , LTrim(RTrim(cu.Lastname)) as Lastname
				 , cu.Address1
				 , cu.Address2
				 , cu.City
				 , cu.County
				 , cu.Postcode
				 , MAX(	Case
							When Convert(Date, cu.ActivatedDate) < DateAdd(day, -2, ncco.Date) Then 'A' -- Adding card to scheme
							Else 'O' -- New Joiner with a card
						End) as [Type]
			Into #Customer
			From #AllCustomer cu
			Inner join #Customer_RBSGSegments rbs
				on cu.FanID = rbs.FanID
			Inner join Relational.CAMEO cam
				on cu.Postcode = cam.Postcode
			Inner join #NewCreditCardOpeners ncco
				on cu.FanID = ncco.UserID
			GROUP BY cu.FanID
				   , Case
				   		When cu.ClubID = 132 then 'NatWest'
				   		When cu.ClubID = 138 then 'RBS'
				     End
				   , LTrim(RTrim(cu.Title))
				   , LTrim(RTrim(cu.Firstname))
				   , LTrim(RTrim(cu.Lastname))
				   , cu.Address1
				   , cu.Address2
				   , cu.City
				   , cu.County
				   , cu.Postcode
							   
		------------------------------------------------------------------------------------
		----------- Add entries to - Warehouse.InsightArchive.CreditCardOpeners ------------
		------------------------------------------------------------------------------------
		
			INSERT INTO [Staging].[CreditCardOpeners]
			SELECT CustomerID AS FanID
				 , Brand
				 , [Private]
				 , [Type]
				 , @Date AS [SendDate]
			FROM #Customer cc
			WHERE NOT EXISTS (SELECT 1
							  FROM [Staging].[CreditCardOpeners] cco
							  WHERE @Date = cco.SendDate
							  AND cc.CustomerID = cco.FanID)

		------------------------------------------------------------------------------------
		-------------------------------------- Display Table Contents ----------------------
		------------------------------------------------------------------------------------

			SELECT *
			FROM #Customer cu
			WHERE EXISTS (	SELECT 1
							FROM [Staging].[CreditCardOpeners] cco
							WHERE SendDate = @Date
							AND cco.FanID = cu.CustomerID)

	End