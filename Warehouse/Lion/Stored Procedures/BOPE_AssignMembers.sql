﻿
CREATE Procedure [Lion].[BOPE_AssignMembers] @JokerSlotPartners_CommaSeperated VarChar(100)
										  , @LionSendID Int

As
Begin



/***********************************************************************************************************************
		1. Fetch all eligible Redemption Items per customer based on Brand or Sector spend and available Club Cash
***********************************************************************************************************************/

		/***************************************************************************************************
				1.1. Fetch live Redemption Items
		***************************************************************************************************/

				/*******************************************************************************
						1.1.1. Fetch list of all live Redmeption Items
				*******************************************************************************/

					If Object_ID('tempdb..#VoucherSetUp_All') Is Not Null Drop Table #VoucherSetUp_All
					Select p.PartnerID
						 , p.PartnerName
						 , p.BrandID
						 , ri.RedeemID
						 , TradeUp_ClubCashRequired as MinCBreq
						 , Dense_Rank() Over (Order by TradeUp_ClubCashRequired Asc) as MinCBreq_Rank
					Into #VoucherSetUp_All
					From Relational.RedemptionItem_TradeUpvalue rtu
					Inner join Relational.RedemptionItem ri
						on ri.RedeemID = rtu.RedeemID
					Inner join Relational.Partner p
						on p.PartnerID = rtu.PartnerID 
					Where ri.Status = 1

				/*******************************************************************************
						1.1.2. Fetch min req spend per Redemption Item and designate jokers
				*******************************************************************************/

						/*******************************************************************************
								1.1.2.1. Convert @JokerSlotPartners_CommaSeperated to temp table
						*******************************************************************************/
				
							If Right(@JokerSlotPartners_CommaSeperated, 1) != ',' Set @JokerSlotPartners_CommaSeperated = Replace(@JokerSlotPartners_CommaSeperated, ' ', '') + ','
				
							If Object_ID('tempdb..#JokerPartners') Is Not Null Drop Table #JokerPartners
							Create Table #JokerPartners (PartnerID Int)
							While Len(@JokerSlotPartners_CommaSeperated) > 1
								Begin
									Insert Into #JokerPartners
									Select Left(@JokerSlotPartners_CommaSeperated, CharIndex(',', @JokerSlotPartners_CommaSeperated) - 1)

									Set @JokerSlotPartners_CommaSeperated = Replace(@JokerSlotPartners_CommaSeperated, Left(@JokerSlotPartners_CommaSeperated, CharIndex(',', @JokerSlotPartners_CommaSeperated)), '')
								End


						/*******************************************************************************
								1.1.2.2. Fetch min req spend and assign jokers based on previos step
						*******************************************************************************/

							If Object_ID('tempdb..#VoucherSetUp') Is Not Null Drop Table #VoucherSetUp
							Select PartnerID
								 , PartnerName
								 , BrandID
								 , MIN(MinCBreq) as MinCBreq
								 , Case
										When r.PartnerID in (Select PartnerID From #JokerPartners) Then 'JokerSlot'
										Else 'DefaultSlot'
								   End as SlotType
							Into #VoucherSetUp
							From #VoucherSetUp_All r
							Group by PartnerID
								   , PartnerName
								   , BrandID


						/*******************************************************************************
								1.1.2.3. Fetch the brands with the 2 lowest denominations
						*******************************************************************************/

							If Object_ID('tempdb..#VoucherSetUp_LowestDenom') Is Not Null Drop Table #VoucherSetUp_LowestDenom
							Select BrandID
							Into #VoucherSetUp_LowestDenom
							From #VoucherSetUp_All
							Where MinCBreq_Rank <= 2						   

		/***************************************************************************************************
				1.2. Fetch all customers and their available cashback
		***************************************************************************************************/
				
			If Object_ID('tempdb..#Customers') Is Not Null Drop Table #Customers
			Select Distinct 
				   cu.FanID
				 , cu.CompositeID
				 , cl.CINID
				 , fa.ClubCashAvailable
			Into #Customers
			From Relational.Customer cu
			Inner join Warehouse.Lion.NominatedLionSendComponent nlsc
				on cu.CompositeId = nlsc.CompositeId
			Inner join SLC_Report..Fan fa
				on cu.FanID = fa.ID
			Left join Relational.CINList cl
				on cu.SourceUID = cl.CIN
						   

		/***************************************************************************************************
				1.3. Construct list of all Fan & Brand combinations to allow for null value joins later
		***************************************************************************************************/
		
			If Object_ID('tempdb..#FanBrandCombinations') Is Not Null Drop Table #FanBrandCombinations
			Select vs.BrandID
				 , cb.FanID
				 , cb.CINID
				 , cb.ClubCashAvailable
			Into #FanBrandCombinations
			From #Customers cb
			Cross join #VoucherSetUp vs 
			Where vs.SlotType = 'DefaultSlot'

			Create Clustered Index CIX_FanBrandCombinations_BrandIDCINIDClubCashAvailable on #FanBrandCombinations (BrandID, CINID, ClubCashAvailable)
						   

		/***************************************************************************************************
				1.4. Fetch list of customers that have had transactions at particular brands
		***************************************************************************************************/

			Declare @Today Date = GetDate()

				/*******************************************************************************
						1.4.1. Create thin version of FanBrandCombinations with join columns
				*******************************************************************************/
				
					If Object_ID('tempdb..#Frame_Sales') Is Not Null Drop Table #Frame_Sales
					Select BrandID
						 , DateAdd(month, -12, @Today) as StartDate
						 , DateAdd(day, -1, @Today) as EndDate
						 , CINID
					Into #Frame_Sales
					From #FanBrandCombinations

					Create Clustered Index CIX_FrameSales_BrandIDStartEndCINID on #Frame_Sales (BrandID, StartDate, EndDate, CINID)


				/*******************************************************************************
						1.4.2. Fetch ConsumerCombinationIDs for Redemption Item brands
				*******************************************************************************/

					If Object_ID('tempdb..#CC') Is Not Null Drop Table #CC
					Select cc.BrandID
						 , cc.ConsumerCombinationID
					Into #CC
					From Relational.ConsumerCombination cc
					Where Exists (Select 1
								  From #VoucherSetUp vs
								  Where cc.BrandID = vs.BrandID)
						
					Create Clustered Index CIX_CC_CCIDBrandID on #CC (ConsumerCombinationID, BrandID)


				/*******************************************************************************
						1.4.3. Fetch list of customers with transactions per brand
				*******************************************************************************/
						   
					If Object_ID('tempdb..#BrandPurchases') Is Not Null Drop Table #BrandPurchases
					Select fs.BrandID
						 , fs.CINID
					Into #BrandPurchases 
					From #Frame_Sales fs
					Where Exists (Select 1
								  From #CC cc
								  Inner join Relational.ConsumerTransaction_MyRewards m 
									  on m.ConsumerCombinationID = cc.ConsumerCombinationID
									  and fs.CINID = m.CINID
									  and m.TranDate Between fs.StartDate and fs.EndDate
								  Where fs.BrandID = cc.BrandID)

					Create Clustered Index CIX_BrandPurchases_BrandIDCINID on #BrandPurchases (BrandID, CINID)
						

		/***************************************************************************************************
				1.5. Fetch list of customers that have had transactions at particular brand sector
		***************************************************************************************************/

				/*******************************************************************************
						1.5.1. Fetch ConsumerCombinationIDs for Redemption Item brand competitors
				*******************************************************************************/

					If Object_ID('tempdb..#CC_Sector') Is Not Null Drop Table #CC_Sector
					Select bc.BrandID
						 , cc.ConsumerCombinationID
					Into #CC_Sector
					From Relational.ConsumerCombination cc
					Inner join Lion.BOPE_BrandCompetitor bc 
						on cc.BrandID = bc.CompetitorBrandID

					Create Clustered Index CIX_CCSector_CCIDBrandID on #CC_Sector (ConsumerCombinationID, BrandID)
					

				/*******************************************************************************
						1.5.2. Fetch list of customers with transactions per brand sector
				*******************************************************************************/

					If Object_ID('tempdb..#SectorPurchases') Is Not Null Drop Table #SectorPurchases
					Select fs.BrandID
						 , fs.CINID
					Into #SectorPurchases
					From #Frame_Sales fs
					Where Exists (Select 1 
								  From #CC_Sector cc
								  Inner join Relational.ConsumerTransaction_MyRewards m 
									   on m.ConsumerCombinationID = cc.ConsumerCombinationID
									   and m.CINID = fs.CINID 
									   and m.TranDate Between fs.StartDate and fs.EndDate
								  Where fs.BrandID = cc.BrandID)

					Create Clustered Index CIX_SectorPurchases_BrandIDCINID on #SectorPurchases (BrandID, CINID)
											   

		/***************************************************************************************************
				1.6. Merge all tables created in previous steps to create pre prioritirisation table
					 This table contains every Customer Brand combination where there is Spend or Sector
					 Spend as a bitflag, allowing for later ranking
		***************************************************************************************************/

			If Object_ID('tempdb..#BaseTable') Is Not Null Drop Table #BaseTable
			Select fbc.BrandID
				 , fbc.FanID
				 , fbc.CINID
				 , fbc.ClubCashAvailable
				 , Case
						When bp.CINID Is Null Then 0
						Else 1
				   End as BrandShop
				 , Case
						When sp.CINID Is Null Then 0
						Else 1
				   End as SectorShop
				 , Case
						When vs.BrandID Is Null Then 0
						Else 1
				   End as CBavailable
			Into #BaseTable
			From #FanBrandCombinations fbc
			Left join #BrandPurchases bp
				on bp.CINID = fbc.CINID
				and bp.BrandID = fbc.BrandID
			Left join #SectorPurchases sp
				on sp.CINID = fbc.CINID
				and sp.BrandID = fbc.BrandID
			Left join #VoucherSetUp vs
				on fbc.ClubCashAvailable >= vs.MinCBreq
				and vs.BrandID = fbc.BrandID
			Where bp.CINID Is Not Null
			Or sp.CINID Is Not Null
			Or vs.BrandID Is Not Null
			Or fbc.brandid in (SELECT BrandID FROM #VoucherSetUp_LowestDenom) 

			Create Clustered Index CIX_BaseTable_BrandIDCINID on #BaseTable (BrandID, CINID)
											   

		/***************************************************************************************************
				1.7. Set the CashbackAvailable flag to 1 for those customers that don't have eligible
				     cashback to redeem at any of our partners
		***************************************************************************************************/

				/*******************************************************************************
						1.7.1. Fetch customers with no cashback available
				*******************************************************************************/
		
					If Object_ID('tempdb..#BaseTable_NoCashback') Is Not Null Drop Table #BaseTable_NoCashback
					Select FanID
					Into #BaseTable_NoCashback
					From #BaseTable
					Group by FanID
					Having Max(CBavailable) = 0

					Create Clustered Index CIX_BaseTableNoCashback_BrandFan On #BaseTable_NoCashback (FanID)

				/*******************************************************************************
						1.7.2. Update Cashback available flag
				*******************************************************************************/

					Update bt
					Set CBavailable = 1
					From #BaseTable bt
					Inner join #BaseTable_NoCashback btnc
						on bt.FanID = btnc.FanID
					WHERE BrandID IN (SELECT BrandID FROM #VoucherSetUp_LowestDenom)


/***********************************************************************************************************************
		2. Prioritise the partners for each redemption offer for the newsletter per customer
***********************************************************************************************************************/

		/***************************************************************************************************
				2.1. Create a priority table for to supplement BOPE logic
		***************************************************************************************************/

			If Object_ID('tempdb..#PriorityTbl') Is Not Null Drop Table #PriorityTbl
			Select bp.BrandID
				 , bp.BrandRank
				 , br.BrandName
				 , Row_Number() Over (Order by BrandRank Desc) as [Priority]
			Into #PriorityTbl
			From (Select bp.BrandID
					   , Sum(1) as BrandRank
				  From #BrandPurchases bp
				  Group by bp.BrandID) bp
			Inner join Relational.Brand br
				on bp.BrandID = br.BrandID
				

		/***************************************************************************************************
				2.2. Select slots 1-4 Where available and fill in blanks with priority table
					 The fith slot is saved for cases where there is a joker redemption item present
		***************************************************************************************************/
		
			Declare @JokerRetailerPresent Bit = 0

			If (Select Count(1) From #VoucherSetUp Where SlotType = 'JokerSlot') != 0 Set @JokerRetailerPresent = 1


				/*******************************************************************************
						2.2.1. Create initial ranking table for all customers
				*******************************************************************************/

					If Object_ID('tempdb..#RankedTable') Is Not Null Drop Table #RankedTable
					Select btr.FanID
						 , btr.BrandID
						 , btr.Rank
						 , '1. AlgoInput' as InputType
					Into #RankedTable
					From (Select bt.FanID
							   , bt.BrandID
							   , Row_Number() Over (Partition by FanID Order by CBavailable Desc, Brandshop Desc, SectorShop Desc, cr.CommercialRank, pt.Priority) as Rank
						  From #BaseTable bt
						  Inner join #PriorityTbl pt
						  	  on bt.BrandID = pt.BrandID
						  Left join Lion.BOPE_BrandCommercialRank cr
							  on bt.BrandID = cr.BrandID) btr
					Where Rank <= 5 - @JokerRetailerPresent

					Create Clustered Index CIX_RankedTable_FanID on #RankedTable (FanID)


				/*******************************************************************************
						2.2.2. Populate customers with < 5 slots from the Priority table
				*******************************************************************************/

						/*******************************************************************************
								2.2.2.1. Calculate the number of slots each customers is missing
						*******************************************************************************/

							If Object_ID('tempdb..#InCompleteCustomers_MaxRank') Is Not Null Drop Table #InCompleteCustomers_MaxRank
							Select FanID
								 , Max(Rank) as MaxRank
								 , 5 - @JokerRetailerPresent - Max(Rank) as NumberOfBlanks
							Into #InCompleteCustomers_MaxRank
							From #RankedTable
							Group by FanID
							Having Count(1) < 5 - @JokerRetailerPresent

							Create Clustered Index CIX_InCompleteCustomersMaxRank_FanID on #InCompleteCustomers_MaxRank (FanID)


						/*******************************************************************************
								2.2.2.2. Seperate customers missing slots from Ranked Table
						*******************************************************************************/

							If Object_ID('tempdb..#InCompleteCustomers') Is Not Null Drop Table #InCompleteCustomers
							Select rt.FanID
								 , rt.BrandID
							Into #InCompleteCustomers
							From #RankedTable rt
							Where Exists (Select 1 
										  From #InCompleteCustomers_MaxRank mr
										  Where rt.FanID = mr.FanID)

							Create Clustered Index CIX_InCompleteCustomers_BrandIDFanID on #InCompleteCustomers (BrandID, FanID)


						/*******************************************************************************
								2.2.2.3. For all cusotmers missing slots, join to Priority Table
										 This is done to populate offers based on overall popularity 
										 per brand where customers might not have transactional data
										 to support previous logic
						*******************************************************************************/

							If Object_ID('tempdb..#InCompleteCustomers_AllBrands') Is Not Null Drop Table #InCompleteCustomers_AllBrands
							Select mr.FanID
								 , pt.BrandID
								 , pt.Priority
							Into #InCompleteCustomers_AllBrands
							From #InCompleteCustomers_MaxRank mr
							Cross join #PriorityTbl pt

							Create Clustered Index CIX_InCompleteCustomersAllBrands_BrandIDFanID on #InCompleteCustomers_AllBrands (BrandID, FanID)


						/*******************************************************************************
								2.2.2.4. Rank all brands from the priority table that the customer
										 is not already assigned to
						*******************************************************************************/

							If Object_ID('tempdb..#InCompleteCustomers_Remainders') Is Not Null Drop Table #InCompleteCustomers_Remainders
							Select ab.FanID
								 , mr.NumberOfBlanks
								 , ab.BrandID
								 , Row_Number() Over (Partition by ab.FanID Order by ab.Priority Desc) as Priority
							Into #InCompleteCustomers_Remainders
							From #InCompleteCustomers_AllBrands ab
							Inner join #InCompleteCustomers_MaxRank mr
								on ab.FanID = mr.FanID
							Where Not Exists (Select 1
											  From #InCompleteCustomers icc
											  Where icc.FanID = ab.FanID
											  and icc.BrandID = ab.BrandID)


						/*******************************************************************************
								2.2.2.5. Fill in the missing slots per customer by inserting all
										 entries from the #InCompleteCustomers_Remainders table
						*******************************************************************************/

							Insert Into #RankedTable (FanID
													, BrandID
													, Rank
													, InputType)
							Select FanID
								 , BrandID
								 , Priority
								 , '2. Remainder'
							From #InCompleteCustomers_Remainders iccr
							Where iccr.Priority <= iccr.NumberOfBlanks


				/*******************************************************************************
						2.2.3. Populate customers that have no slots assgined from the
							   Priority table
				*******************************************************************************/

						/*******************************************************************************
								2.2.3.1. Fetch customers that have no slots populated
						*******************************************************************************/

							If Object_ID('tempdb..#EmptyCustomers') Is Not Null Drop Table #EmptyCustomers
							Select FanID
							Into #EmptyCustomers
							From #Customers cu
							Where Not Exists (Select 1
											  From #RankedTable rt
											  Where rt.FanID = cu.FanID)

							Create Clustered Index CIX_EmptyCustomers_FanID on #EmptyCustomers (FanID)


						/*******************************************************************************
								2.2.3.2. Assign the top 5 brands from the priority table
						*******************************************************************************/

							If Object_ID('tempdb..#EmptyCustomers_Allocated') Is Not Null Drop Table #EmptyCustomers_Allocated
							Select ef.FanID
								 , pt.BrandID
								 , pt.Priority
								 , '3. AllZeroInputs' as InputType
							Into #EmptyCustomers_Allocated
							From #EmptyCustomers ef
							Cross join #PriorityTbl pt
							Where Priority <= 5 - @JokerRetailerPresent
						

		/***************************************************************************************************
				2.3. If there is a joker redemption item live then force in for all customers
		***************************************************************************************************/

			If Object_ID('tempdb..#Customers_JokerSlots') Is Not Null Drop Table #Customers_JokerSlots
			Create Table #Customers_JokerSlots (FanID Int
										 , BrandID Int
										 , Priority Int
										 , InputType VarChar(30))


				/*******************************************************************************
						2.3.1. Randomly select 1 joker redemption item per customer
				*******************************************************************************/

					If (@JokerRetailerPresent = 1)
					Begin
						If Object_ID('tempdb..#Jokers') Is Not Null Drop Table #Jokers
						Select vs.PartnerID
							 , vs.BrandID
							 , Row_number() Over (Order by NewID()) as ID
						Into #Jokers
						From #VoucherSetUp vs
						Where SlotType = 'JokerSlot'

						Declare @JokerRetailers Int = (Select Count(1) From #VoucherSetUp Where SlotType = 'JokerSlot')

						If Object_ID('tempdb..#JokerIDAllocation') Is Not Null Drop Table #JokerIDAllocation
						Select FanID
							 , ntile(@JokerRetailers) Over (Order by NewID()) as ID
						Into #JokerIDAllocation
						From #Customers

						Create Clustered Index CIX_JokerIDAllocation_FanIDID on #JokerIDAllocation (FanID, ID)
	
						Insert Into #Customers_JokerSlots
						Select ja.FanID
							 , BrandID
							 , 5 as Priority
							 , '4. Joker' as InputType
						From #JokerIDAllocation ja
						Inner join #Jokers j
							on ja.ID = j.ID
					End
				

		/***************************************************************************************************
				2.4. Join all tables together to get the top 5 redemption offers per customer
		***************************************************************************************************/
				
			If Object_ID('tempdb..#Allocated_Retailers') Is Not Null Drop Table #Allocated_Retailers
			Select FanID
				 , BrandID
				 , Rank
				 , InputType
			Into #Allocated_Retailers
			From (Select *
				  From #RankedTable
				  Union All
				  Select *
				  From #EmptyCustomers_Allocated
				  Union All
				  Select *
				  From #Customers_JokerSlots) [all]

/***********************************************************************************************************************
		3. Assign the most relevant redemption item per redemption partner per customer
***********************************************************************************************************************/

		/***************************************************************************************************
				3.1. Rank the redemption items by club cash required for redemption
		***************************************************************************************************/
				
			If Object_ID('tempdb..#DenominationsTable') Is Not Null Drop Table #DenominationsTable
			Select cv.PartnerID
				 , cv.BrandID
				 , RedeemID
				 , MinCBreq
				 , Row_Number() Over (Partition by BrandID Order by MinCBreq Asc) as MinIndicator
				 , Row_Number() Over (Partition by BrandID Order by MinCBreq Desc) as MaxIndicator
			Into #DenominationsTable
			From #VoucherSetUp_All cv


		/***************************************************************************************************
				3.2. Join the new ranked table to the full allocated retailers table, selecting
					 the minimum value voucher that the customer can currently trade up for
					 or the minimum value voucher where they don't meet the club cash requirements
					 for any redemption item per partner
		***************************************************************************************************/

			If Object_ID('tempdb..#Allocated_RetailerVouchers_Pre') Is Not Null Drop Table #Allocated_RetailerVouchers_Pre
			Select rv.CompositeID
				 , rv.BrandID
				 , rv.Rank
				 , rv.InputType
				 , rv.RedeemID
				 , rv.MinCBreq
				 , rv.ID
			Into #Allocated_RetailerVouchers_Pre
			From (Select cu.CompositeID
				  	   , ar.BrandID
				  	   , ar.Rank
				  	   , ar.InputType
				  	   , dt.RedeemID
				  	   , dt.MinCBreq
				  	   , Row_Number() Over (Partition by ar.FanID, ar.BrandID Order by MinCBreq desc) as ID
				  From #Allocated_Retailers ar
				  Inner join #Customers cu
				  	  on ar.FanID = cu.FanID
				  Left join #DenominationsTable dt
				  	  on ar.BrandID = dt.BrandID
				  	  and cu.ClubCashAvailable >= dt.MinCBreq) rv
			Where ID Is Null
			Or ID = 1


		/***************************************************************************************************
				3.3. Populate final output table
		***************************************************************************************************/

			Truncate Table Lion.NominatedLionSendComponent_RedemptionOffers

			Insert Into Lion.NominatedLionSendComponent_RedemptionOffers (LionSendID
																		, CompositeID
																		, TypeID
																		, ItemRank
																		, ItemID)
			Select @LionSendID as LionSendID
				 , rvp.CompositeID
				 , 3 as TypeID
				 , Case
						When Row_Number() Over (Partition by CompositeID Order by InputType Asc, Rank Asc) = 1 Then 5
						Else Row_Number() Over (Partition by CompositeID Order by InputType Asc, Rank Asc) - 1
				   End as ItemRank
				 , Coalesce(rvp.RedeemID, dt.RedeemID) as ItemID
			From #Allocated_RetailerVouchers_Pre rvp
			Inner join (Select BrandID
							 , RedeemID
						From #DenominationsTable
						Where MinIndicator = 1) dt
				on rvp.BrandID = dt.BrandID	

End