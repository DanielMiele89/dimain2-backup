﻿
CREATE Procedure [Staging].[SSRS_R0196_ReducedBrandSpendReport_V2]  (@BrandID VarChar(200))
As
Begin

	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandIDs') Is Not Null Drop Table #BrandIDs
		Create Table #BrandIDs (BrandID Int)

		/***********************************************************************************************************************
			1.1. Declare & set starting parameters
		***********************************************************************************************************************/

		Declare @MonthCount TinyInt
			  , @StartDate Date
			  , @EndDate Date
			  , @TotalCustomers Int = (Select Max(TotalCustomerCountThisYear) From MI.GrandTotalCustomers)
			  , @TotalCustomersRBS Int

		Set @MonthCount = 12 --nb: 12 required for correct TotalCustomers figure which is taken from the total brand spend process


		Set @EndDate = DateFromParts(year(GetDate()), month(GetDate()), 1)
		Set @StartDate = DateAdd(month, -@MonthCount, @EndDate)
		Set @EndDate = DateAdd(day, -1, @EndDate)

			/***********************************************************************************************************************
				1.1.1. Update @BrandID to entires that have been recently branded if the process is executed through ReportServer
			***********************************************************************************************************************/

				DECLARE @ConsumerCombinationChangeLogMaxDate DATE = (SELECT MAX(DateResolved) FROM Staging.ConsumerCombination_ChangeLog)

				IF @BrandID IS NULL
					BEGIN
						INSERT INTO #BrandIDs
						SELECT DISTINCT BrandID
						FROM Staging.ConsumerCombination_ChangeLog
						WHERE DateResolved =  @ConsumerCombinationChangeLogMaxDate
					END


		/***********************************************************************************************************************
			1.2. Split @BrandID input into individual BrandIDs & insert to temp table
		***********************************************************************************************************************/

			INSERT INTO #BrandIDs
			SELECT CONVERT(INT, Item) AS BrandID
			FROM dbo.il_SplitDelimitedStringArray (@BrandID, ',')

			Create Clustered Index CIX_BrandIDs_BrandID on #BrandIDs (BrandID)

	/*******************************************************************************************************************************************
		2. Fetch currently active customers and save as parameter
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#RBSCustomers') Is Not Null Drop Table #RBSCustomers
		Create Table #RBSCustomers (CINID Int Primary Key Clustered)

		Insert Into #RBSCustomers (CINID)
		Select cl.CINID
		From Relational.Customer cu
		Inner join Relational.CINList cl
			on cu.SourceUID = cl.CIN
		Where cu.CurrentlyActive = 1
		And Not Exists (Select 1
						From MI.CINDuplicate cld
						Where cu.FanID = cld.FanID)
	
		Select @TotalCustomersRBS = Count(1)
		From #RBSCustomers


	/*******************************************************************************************************************************************
		3. Fetch all ConsumerCombinations for Selected Brands
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandConsumerCombination') Is Not Null Drop Table #BrandConsumerCombination
		Select cc.BrandID
			 , cc.ConsumerCombinationID
		Into #BrandConsumerCombination
		From Relational.ConsumerCombination cc
		Inner join #BrandIDs br
			on cc.BrandID = br.BrandID

		Create Unique Clustered Index UCIX_CC on #BrandConsumerCombination (ConsumerCombinationID)


	/*******************************************************************************************************************************************
		4. Fetch spend stats for each of the BrandIDs input into the report
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandStats') Is Not Null Drop Table #BrandStats
		Create Table #BrandStats (ID TinyInt Primary Key Identity
								, BrandID SmallInt Not Null
								, RowType VarChar(50) Not Null
								, Spend Money Not Null
								, OnlineSpend Money Not Null
								, Transactions Int Not Null
								, UniqueSpenders Int Not Null
								, TotalCustomers Int Not Null
								, AvgTranFreq Float Not Null
								, AvgTranValue Money Not Null
								, OnlineAvgTranValue Money Null
								, SpendPerSpender Money Not Null
								, CustomerPenetration Float Not Null)


		/***********************************************************************************************************************
			4.1. Fetch all spend from all customers
		***********************************************************************************************************************/

			Insert Into #BrandStats (BrandID
								   , RowType
								   , Spend
								   , OnlineSpend
								   , Transactions
								   , UniqueSpenders
								   , TotalCustomers
								   , AvgTranFreq
								   , AvgTranValue
								   , OnlineAvgTranValue
								   , SpendPerSpender
								   , CustomerPenetration)
			Select ct.BrandID
				 , 'All Spend' as RowType
				 , Sum(ct.Amount) as Spend
				 , Sum(Case
							When ct.IsOnline = 1 then Amount 
							Else 0
					   End) as OnlineSpend
				, Count(1) as Transactions
				, Count(Distinct ct.CINID) as UniqueSpenders
				, @TotalCustomers as TotalCustomers
				, Convert(Float, Count(1)) / Count(Distinct ct.CINID) as AvgTranFreq
				, Sum(ct.Amount) / Count(1) as AvgTranValue
				, ISNULL(Sum(Case
							When ct.IsOnline = 1 then Amount 
							Else NULL
					   End) / 
				  Sum(Case
							When ct.IsOnline = 1 then 1 
							Else NULL
					   End), 0) as OnlineAvgTranValue
				, Sum(ct.Amount) / Count(Distinct ct.CINID) as SpendPerSpender
				, Convert(Float, Count(Distinct ct.CINID)) / @TotalCustomers as CustomerPenetration
			From (	SELECT ct.FileID
						 , ct.RowNum
						 , ct.CINID
						 , ct.Amount
						 , ct.IsOnline
						 , bcc.BrandID
					FROM Relational.ConsumerTransaction ct
					Inner join #BrandConsumerCombination bcc
						on ct.ConsumerCombinationID = bcc.ConsumerCombinationID
					Where ct.TranDate Between @StartDate And @EndDate
					UNION
					SELECT ct.FileID
						 , ct.RowNum
						 , ct.CINID
						 , ct.Amount
						 , ct.IsOnline
						 , bcc.BrandID
					FROM Relational.ConsumerTransaction_CreditCard ct
					Inner join #BrandConsumerCombination bcc
						on ct.ConsumerCombinationID = bcc.ConsumerCombinationID
					Where ct.TranDate Between @StartDate And @EndDate) ct
			Group by ct.BrandID

		/***********************************************************************************************************************
			4.2. Fetch all spend from RBS customers only
		***********************************************************************************************************************/

			Insert Into #BrandStats (BrandID
								   , RowType
								   , Spend
								   , OnlineSpend
								   , Transactions
								   , UniqueSpenders
								   , TotalCustomers
								   , AvgTranFreq
								   , AvgTranValue
								   , OnlineAvgTranValue
								   , SpendPerSpender
								   , CustomerPenetration)
			Select ct.BrandID
				 , 'MyRewards Spend' as RowType
				 , Sum(ct.Amount) as Spend
				 , Sum(Case
							When ct.IsOnline = 1 then Amount 
							Else 0
					   End) as OnlineSpend
				, Count(1) as Transactions
				, Count(Distinct ct.CINID) as UniqueSpenders
				, @TotalCustomersRBS as TotalCustomers
				, Convert(Float, Count(1)) / Count(Distinct ct.CINID) as AvgTranFreq
				, Sum(ct.Amount) / Count(1) as AvgTranValue
				, isnull(Sum(Case
							When ct.IsOnline = 1 then Amount 
							Else NULL
					   End) / 
				  Sum(Case
							When ct.IsOnline = 1 then 1 
							Else NULL
					   End) , 0) as OnlineAvgTranValue
				, Sum(ct.Amount) / Count(Distinct ct.CINID) as SpendPerSpender
				, Convert(Float, Count(Distinct ct.CINID)) / @TotalCustomersRBS as CustomerPenetration
			From (	SELECT ct.FileID
						 , ct.RowNum
						 , ct.CINID
						 , ct.Amount
						 , ct.IsOnline
						 , bcc.BrandID
					FROM Relational.ConsumerTransaction ct
					Inner join #BrandConsumerCombination bcc
						on ct.ConsumerCombinationID = bcc.ConsumerCombinationID
					Where ct.TranDate Between @StartDate And @EndDate
					And Exists (Select 1
								From #RBSCustomers rbs
								Where ct.CINID = rbs.CINID)
					UNION
					SELECT ct.FileID
						 , ct.RowNum
						 , ct.CINID
						 , ct.Amount
						 , ct.IsOnline
						 , bcc.BrandID
					FROM Relational.ConsumerTransaction_CreditCard ct
					Inner join #BrandConsumerCombination bcc
						on ct.ConsumerCombinationID = bcc.ConsumerCombinationID
					Where ct.TranDate Between @StartDate And @EndDate
					And Exists (Select 1
								From #RBSCustomers rbs
								Where ct.CINID = rbs.CINID)) ct
			Group by ct.BrandID


	/*******************************************************************************************************************************************
		5. Fetch all ConsumerCombinations for Selected Brands (Direct Debit)
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandConsumerCombination_DD') Is Not Null Drop Table #BrandConsumerCombination_DD
		Select cc.BrandID
			 , cc.ConsumerCombinationID_DD
		Into #BrandConsumerCombination_DD
		From Relational.ConsumerCombination_DD cc
		Inner join #BrandIDs br
			on cc.BrandID = br.BrandID

		Create Unique Clustered Index UCIX_CC on #BrandConsumerCombination_DD (ConsumerCombinationID_DD)


	/*******************************************************************************************************************************************
		6. Fetch spend stats for each of the BrandIDs input into the report
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandStats_DD') Is Not Null Drop Table #BrandStats_DD
		Create Table #BrandStats_DD (ID TinyInt Primary Key Identity
								   , BrandID SmallInt Not Null
								   , RowType VarChar(50) Not Null
								   , Spend Money Not Null
								   , Transactions Int Not Null
								   , UniqueSpenders Int Not Null
								   , TotalCustomers Int Not Null
								   , AvgTranFreq Float Not Null
								   , AvgTranValue Money Not Null
								   , SpendPerSpender Money Not Null
								   , CustomerPenetration Float Not Null)


		/***********************************************************************************************************************
			4.1. Fetch all spend from all customers
		***********************************************************************************************************************/

			Insert Into #BrandStats_DD (BrandID
									  , RowType
									  , Spend
									  , Transactions
									  , UniqueSpenders
									  , TotalCustomers
									  , AvgTranFreq
									  , AvgTranValue
									  , SpendPerSpender
									  , CustomerPenetration)
			Select bcc.BrandID
				 , 'All Spend' as RowType
				 , Sum(ct.Amount) as Spend
				 , Count(1) as Transactions
				 , Count(Distinct ct.BankAccountID) as UniqueSpenders
				 , @TotalCustomers as TotalCustomers
				 , Convert(Float, Count(1)) / Count(Distinct ct.BankAccountID) as AvgTranFreq
				 , Sum(ct.Amount) / Count(1) as AvgTranValue
				 , Sum(ct.Amount) / Count(Distinct ct.BankAccountID) as SpendPerSpender
				 , Convert(Float, Count(Distinct ct.BankAccountID)) / @TotalCustomers as CustomerPenetration
			From Relational.ConsumerTransaction_DD ct With (NoLock)
			Inner join #BrandConsumerCombination_DD bcc
				on ct.ConsumerCombinationID_DD = bcc.ConsumerCombinationID_DD
			Where ct.TranDate Between @StartDate And @EndDate
			Group by bcc.BrandID


		/***********************************************************************************************************************
			4.2. Fetch all spend from RBS customers only
		***********************************************************************************************************************/

			Insert Into #BrandStats_DD (BrandID
									  , RowType
									  , Spend
									  , Transactions
									  , UniqueSpenders
									  , TotalCustomers
									  , AvgTranFreq
									  , AvgTranValue
									  , SpendPerSpender
									  , CustomerPenetration)
			Select bcc.BrandID
				 , 'MyRewards Spend' as RowType
				 , Sum(ct.Amount) as Spend
				, Count(1) as Transactions
				, Count(Distinct ct.BankAccountID) as UniqueSpenders
				, @TotalCustomersRBS as TotalCustomers
				, Convert(Float, Count(1)) / Count(Distinct ct.BankAccountID) as AvgTranFreq
				, Sum(ct.Amount) / Count(1) as AvgTranValue
				, Sum(ct.Amount) / Count(Distinct ct.BankAccountID) as SpendPerSpender
				, Convert(Float, Count(Distinct ct.BankAccountID)) / @TotalCustomersRBS as CustomerPenetration
			From Relational.ConsumerTransaction_DD_MyRewards ct With (NoLock)
			Inner join #BrandConsumerCombination_DD bcc
				on ct.ConsumerCombinationID_DD = bcc.ConsumerCombinationID_DD
			Where ct.TranDate Between @StartDate And @EndDate
			Group by bcc.BrandID


	/*******************************************************************************************************************************************
		7. Output results
	*******************************************************************************************************************************************/

		Select bst.ID
			 , br.BrandID
			 , br.BrandName
			 , bse.SectorName
			 , bsg.GroupName as SectorGroupName
			 , bst.RowType
			 , 'POS' AS TransactionType
			 , bst.Spend
			 , bst.OnlineSpend
			 , bst.Transactions
			 , bst.UniqueSpenders
			 , bst.TotalCustomers
			 , bst.AvgTranFreq
			 , bst.AvgTranValue
			 , bst.OnlineAvgTranValue
			 , bst.SpendPerSpender
			 , bst.CustomerPenetration
		From #BrandStats bst
		Inner join Relational.Brand br
			on bst.BrandID = br.BrandID
		Inner join Relational.BrandSector bse
			on br.SectorID = bse.SectorID
		Inner join Relational.BrandSectorGroup bsg
			on bse.SectorGroupID = bsg.SectorGroupID
		UNION ALL
		Select bst.ID
			 , br.BrandID
			 , br.BrandName
			 , bse.SectorName
			 , bsg.GroupName as SectorGroupName
			 , bst.RowType
			 , 'DD' AS TransactionType
			 , bst.Spend
			 , 0 AS OnlineSpend
			 , bst.Transactions
			 , bst.UniqueSpenders
			 , bst.TotalCustomers
			 , bst.AvgTranFreq
			 , bst.AvgTranValue
			 , 0 AS OnlineAvgTranValue
			 , bst.SpendPerSpender
			 , bst.CustomerPenetration
		From #BrandStats_DD bst
		Inner join Relational.Brand br
			on bst.BrandID = br.BrandID
		Inner join Relational.BrandSector bse
			on br.SectorID = bse.SectorID
		Inner join Relational.BrandSectorGroup bsg
			on bse.SectorGroupID = bsg.SectorGroupID
		Order by br.BrandName
			   , bst.RowType

End





