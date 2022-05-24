/*
	Author:			Stuart Barnley

	Date:			17-11-2015

	Purpose:		To provide a list of customers who have opened a MyRewards credit
					card, this is sent to a mailhouse so they can be sent the 
					introductory information.

	Updates:		N/A


*/
CREATE Procedure [Staging].[SSRS_R0198_CreditCardOpenersMailer_Old]
With Execute as Owner
as
Begin

	Declare @Date Date = GetDate()
		  , @Startdate Date			-- Is used to hold the date the cards should have been added from
		  , @EndDate Date			-- Is used to hold the date the cards should have been added by
		  , @TableName VarChar(300)	-- This is the name of the new data table that will be created
		  , @Qry nVarChar(500)		-- This is used to hold any query that needs to be generated then run

	Set @TableName = 'Warehouse.InsightArchive.CreditCardOpenerCustomers_' + Convert(VarChar, GetDate(), 112)

	----------------------------------------------------------------------------------
	-------------Use todays date to go back and select customers ---------------------
	----------------------------------------------------------------------------------

	Set DateFirst 1
	Set @StartDate = DateAdd(day, -11, (Select [Staging].[fnGetStartOfWeek](@Date)))
	Set @EndDate = DateAdd(day, 6, @StartDate)

	----------------------------------------------------------------------------------
	-------------- Select the customers that need to be contacted --------------------
	----------------------------------------------------------------------------------

	If Object_ID('tempdb..#ExistingCreditCardOpeners') Is Not Null Drop Table #ExistingCreditCardOpeners
	Select FanID
	Into #ExistingCreditCardOpeners
	From Staging.CreditCardOpeners
	Where SendDate > DateAdd(day, -35, @Date)

	Create Clustered Index CIX_ExistingCreditCardOpeners_FanID On #ExistingCreditCardOpeners (FanID)

	If Object_ID('tempdb..#NewCreditCardOpeners') Is Not Null Drop Table #NewCreditCardOpeners
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

	Create Clustered Index CIX_NewCreditCardOpeners_UserID On #NewCreditCardOpeners (UserID)

	If Object_ID('tempdb..#Customer_Temp') Is Not Null Drop Table #Customer_Temp
	Select cu.FanID as CustomerID
		 , Case
				When cu.ClubID = 132 then 'NatWest'
				When cu.ClubID = 138 then 'RBS'
		   End as Brand
		 , Case
				When rbs.CustomerSegment Is Null Then 'N' -- Core
				When rbs.CustomerSegment = 'V' Then 'Y'   -- Private
				Else 'N'
		   End as [Private]
		 , LTrim(RTrim(cu.Title)) as Title
		 , LTrim(RTrim(cu.Firstname)) as Firstname
		 , LTrim(RTrim(cu.Lastname)) as Lastname
		 , cu.Address1
		 , cu.Address2
		 , cu.City
		 , cu.County
		 , cu.Postcode
		 , Case
				When Convert(Date, cu.ActivatedDate) < DateAdd(day, -2, ncco.Date) Then 'A' -- Adding card to scheme
				Else 'O' -- New Joiner with a card
		   End as [Type]
	Into #Customer_Temp
	From Relational.Customer cu
	Inner join Relational.Customer_RBSGSegments rbs
		on cu.FanID = rbs.FanID
	Inner join Relational.CAMEO cam
		on cu.Postcode = cam.Postcode
	Inner join #NewCreditCardOpeners ncco
		on cu.FanID = ncco.UserID
	Where rbs.EndDate Is Null
	And cu.CurrentlyActive = 1
	And (cu.EmailStructureValid = 0 or cu.ActivatedOffline = 1)
	And Len(cu.FirstName) > 1
	And Len(cu.Lastname) > 1

	If Object_ID('tempdb..#Customer') Is Not Null Drop Table #Customer
	Select CustomerID
		 , Brand
		 , Max([Private]) as [Private]
		 , Title
		 , Firstname
		 , Lastname
		 , Address1
		 , Address2
		 , City
		 , County
		 , Postcode
		 , Max([Type]) as [Type]
	Into #Customer
	From #Customer_Temp
	Group By CustomerID
			,Brand
			,Title
			,Firstname
			,Lastname
			,Address1
			,Address2
			,City
			,County
			,Postcode

	------------------------------------------------------------------------------------
	-- Create table of data - Warehouse.InsightArchive.CreditCardOpenerCustomers_XXXX---
	------------------------------------------------------------------------------------

	Set @Qry = '
	If Object_ID(''' + @TableName + ''') Is Null
	Select * 
	Into ' + @TableName + ' 
	From #Customer'

	Exec (@Qry)

	------------------------------------------------------------------------------------
	----------- Add entries to - Warehouse.InsightArchive.CreditCardOpeners ------------
	------------------------------------------------------------------------------------
	Set @Qry = '
	Insert Into Warehouse.Staging.CreditCardOpeners 
	Select CustomerID as FanID
		 , Brand
		 , [Private]
		 , [Type]
		 , Cast(''' + Convert(Varchar, @Date, 120) + ''' as Date) as [SendDate]
	From ' + @TableName + ' cc
	Where Not Exists (Select 1
					  From Warehouse.Staging.CreditCardOpeners cco
					  Where Cast(''' + Convert(Varchar, @Date, 120) + ''' as Date) = cco.SendDate
					  And cc.CustomerID = cco.FanID)'

	Exec (@Qry)

	------------------------------------------------------------------------------------
	-------------------------------------- Display Table Contents ----------------------
	------------------------------------------------------------------------------------

	Set @Qry = 'Select * From ' + @TableName

	Exec (@Qry)

End