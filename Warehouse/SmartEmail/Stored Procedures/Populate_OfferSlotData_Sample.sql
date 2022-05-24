/*

	Author:	Stuart Barnley

	Date:	26th October 2017

	Purpose:	Convert data from NominatedLionSendComponent to fit in the new 
				structure for SmartEmail (Sand box.Stuart.[OfferSlotData])


*/
CREATE Procedure [SmartEmail].[Populate_OfferSlotData_Sample] (@LSID INT
															, @EmailDate DATE)
As

Declare @LionSendID INT = @LSID
	  , @Date DATE = @EmailDate
	  , @ExistingSampleCustomers INT = (SELECT COUNT(1) FROM [SmartEmail].[SampleCustomerLinks]) + 1

	--------------------------------------------------------------------------------------------
	----------------------------Create a list of Customers (with RowNo)-------------------------
	--------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT cu.CompositeID
		 , cu.FanID
		 , ROW_NUMBER() OVER (ORDER BY cu.CompositeID ASC) + @ExistingSampleCustomers AS RowNo
	INTO #Customers
	FROM Relational.Customer cu
	WHERE EXISTS (SELECT 1
				  FROM Lion.NominatedLionSendComponent ls
				  WHERE cu.CompositeID = ls.CompositeID
				  AND ls.LionSendID = @LionSendID)

	Create Clustered Index cix_Customers_CompositeID on #Customers (CompositeID)


	--------------------------------------------------------------------------------------------
	--------------------------Update Links (Real Customer to Sample) Table----------------------
	--------------------------------------------------------------------------------------------

	INSERT INTO [SmartEmail].[SampleCustomerLinks] --** Insert new mapping
	SELECT RowNo AS SampleCustomerID
		 , FanID AS RealCustomerFanID
	FROM #Customers

	
	--------------------------------------------------------------------------------------------
	----------------------------------Get Customer with OfferIDs--------------------------------
	--------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
	SELECT cu.CompositeId
		 , cu.FanID
		 , ItemID AS IronOfferID
		 , ItemRank AS Slot
	INTO #Offers
	FROM #Customers cu
	INNER JOIN Lion.NominatedLionSendComponent nlsc
		ON cu.CompositeId = nlsc.CompositeId
	WHERE LionSendID = @LionSendID

	CREATE CLUSTERED INDEX Offers_IronOfferID_CompositeID ON #Offers (IronOfferID, CompositeID)


	--------------------------------------------------------------------------------------------
	--------------------------------------Get IOM Memberships-----------------------------------
	--------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#OfferDates') IS NOT NULL DROP TABLE #OfferDates
	Select o.CompositeId
		 , o.FanID
		 , o.IronOfferID
		 , o.Slot
		 , iom.StartDate as StartDate
		 , iom.EndDate as EndDate
	Into #OfferDates
	From #Offers o
	Inner join SLC_Report..IronOfferMember iom
		on o.CompositeId = iom.CompositeId
		and o.IronOfferID = iom.IronOfferID
	Where (iom.StartDate <= @Date Or iom.StartDate Is Null) 
	And (iom.EndDate > @Date Or iom.EndDate Is Null)

	Create Clustered Index cix_OD_CompositeID_IronOfferID on #OfferDates (CompositeID, IronOfferID)


	--------------------------------------------------------------------------------------------
	-----------------------Get OMA Memberships (for those missing)------------------------------
	--------------------------------------------------------------------------------------------

	Insert into #OfferDates
	Select o.CompositeID
		 , o.FanID
		 , o.IronOfferID
		 , o.Slot
		 , oma.StartDate as StartDate
		 , oma.EndDate as EndDate
	From #Offers o
	Inner join iron.OfferMemberAddition oma
		on o.CompositeID = oma.CompositeID
		and o.IronOfferID = oma.IronOfferID
	Where (oma.StartDate <= @Date Or oma.StartDate Is Null) 
	And (oma.EndDate > @Date Or oma.EndDate Is Null)
	And Not Exists (Select 1
					From #OfferDates od
					Where o.CompositeID = od.CompositeID
					And o.IronOfferID = od.IronOfferID)

	Create NonClustered index #OfferDates_FanID on #OfferDates (FanID)


	--------------------------------------------------------------------------------------------
	-------------------------------------Insert Data into Table---------------------------------
	--------------------------------------------------------------------------------------------

	Insert into Warehouse.SmartEmail.[OfferSlotData] -- Real Table
	Select scls.[FanID]
		 , @LionSendID as [LionSendID]
		 , [Offer1]
		 , [Offer2]
		 , [Offer3]
		 , [Offer4]
		 , [Offer5]
		 , [Offer6]
		 , [Offer7]
		 , Case
				When [Offer1StartDate] = '1900-01-01' then NULL
				Else [Offer1StartDate]
			 End as [Offer1StartDate]
		 , Case
				When [Offer2StartDate] = '1900-01-01' then NULL
				Else [Offer2StartDate]
			 End as [Offer2StartDate]
		 , Case
				When [Offer3StartDate] = '1900-01-01' then NULL
				Else [Offer3StartDate]
			 End as [Offer3StartDate]
		 , Case
				When [Offer4StartDate] = '1900-01-01' then NULL
				Else [Offer4StartDate]
			 End as [Offer4StartDate]
		 , Case
				When [Offer5StartDate] = '1900-01-01' then NULL
				Else [Offer5StartDate]
			 End as [Offer5StartDate]
		 , Case
				When [Offer6StartDate] = '1900-01-01' then NULL
				Else [Offer6StartDate]
			 End as [Offer6StartDate]
		 , Case
				When [Offer7StartDate] = '1900-01-01' then NULL
				Else [Offer7StartDate]
			 End as [Offer7StartDate]
		 , Case
				When [Offer1EndDate] = '1900-01-01' then NULL
				Else [Offer1EndDate]
			 End as [Offer1EndDate]
		 , Case
				When [Offer2EndDate] = '1900-01-01' then NULL
				Else [Offer2EndDate]
			 End as [Offer2EndDate]
		 , Case
				When [Offer3EndDate] = '1900-01-01' then NULL
				Else [Offer3EndDate]
			 End as [Offer3EndDate]
		 , Case
				When [Offer4EndDate] = '1900-01-01' then NULL
				Else [Offer4EndDate]
			 End as [Offer4EndDate]
		 , Case
				When [Offer5EndDate] = '1900-01-01' then NULL
				Else [Offer5EndDate]
			 End as [Offer5EndDate]
		 , Case
				When [Offer6EndDate] = '1900-01-01' then NULL
				Else [Offer6EndDate]
			 End as [Offer6EndDate]
		 , Case
				When [Offer7EndDate] = '1900-01-01' then NULL
				Else [Offer7EndDate]
			 End as [Offer7endDate]
	From (Select FanID
			   , Max(Case
					 	When Slot = 1 then IronOfferID
					 	Else 0
					 End) as Offer1
			   , Max(Case
						When Slot = 2 then IronOfferID
						Else 0
					 End) as Offer2
			   , Max(Case
						When Slot = 3 then IronOfferID
						Else 0
					 End) as Offer3
			   , Max(Case
						When Slot = 4 then IronOfferID
						Else 0
					 End) as Offer4
			   , max(Case
						When Slot = 5 then IronOfferID
						Else 0
					 End) as Offer5
			   , Max(Case
						When Slot = 6 then IronOfferID
						Else 0
					 End) as Offer6
			   , Max(Case
						When Slot = 7 then IronOfferID
						Else 0
					 End) as Offer7
			   , Max(Case
						When Slot = 1 then StartDate
						Else 0
					 End) as Offer1StartDate
			   , Max(Case
						When Slot = 2 then StartDate
						Else 0
					 End) as Offer2StartDate
			   , Max(Case
						When Slot = 3 then StartDate
						Else 0
					 End) as Offer3StartDate
			   , Max(Case
						When Slot = 4 then StartDate
						Else 0
					 End) as Offer4StartDate
			   , Max(Case
						When Slot = 5 then StartDate
						Else 0
					 End) as Offer5StartDate
			   , Max(Case
						When Slot = 6 then StartDate
						Else 0
					 End) as Offer6StartDate
			   , Max(Case
						When Slot = 7 then StartDate
						Else 0
					 End) as Offer7StartDate
			   , Max(Case
						When Slot = 1 then EndDate
						Else 0
					 End) as Offer1EndDate
			   , Max(Case
						When Slot = 2 then EndDate
						Else 0
					 End) as Offer2EndDate
			   , Max(Case
						When Slot = 3 then EndDate
						Else 0
					 End) as Offer3EndDate
			   , Max(Case
						When Slot = 4 then EndDate
						Else 0
					 End) as Offer4EndDate
			   , Max(Case
						When Slot = 5 then EndDate
						Else 0
					 End) as Offer5EndDate
			   , Max(Case
						When Slot = 6 then EndDate
						Else 0
					 End) as Offer6EndDate
			   , Max(Case
						When Slot = 7 then EndDate
						Else 0
					 End) as Offer7EndDate
		  From #OfferDates
		  Group by FanID) od
	Inner join SmartEmail.SampleCustomerLinks scln
		on od.FanID = scln.RealCustomerFanID
	Inner join SmartEmail.SampleCustomersList scls
		on scln.SampleCustomerID = scls.ID