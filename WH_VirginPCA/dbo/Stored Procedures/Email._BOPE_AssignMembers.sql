
CREATE PROCEDURE [dbo].[Email.[BOPE_AssignMembers] (@JokerSlotPartners_CommaSeperated VARCHAR(100))

AS
BEGIN

/***********************************************************************************************************************
		1. Fetch all eligible Redemption Items per customer based on Brand or Sector spend and available Club Cash
***********************************************************************************************************************/

	--DECLARE @JokerSlotPartners_CommaSeperated VARCHAR(100) = ''

		/***************************************************************************************************
				1.1. Fetch live Redemption Items
		***************************************************************************************************/

					-- Notes:
					-- 1: Modified AVIOS BrandID to that of BA's as AVIOS is no longer a joker retailer and purchases "at AVIOS" are substituted for "purchases at BA"
					-- 2: Creating composite BrandID for Waitrose & John Lewis, temp BrandID used is the (max + 1) in the brand table at the time of run.

					-- New brandid
					declare @BrandID_WRJL int = (select 1 + max(BrandID) from warehouse.relational.Brand)

					-- Brand table
					If Object_ID('tempdb..#Brand') Is Not Null Drop Table #Brand
					select cast(b.brandid as int) as BrandID, BrandName, IsLivePartner, BrandGroupID, SectorID, cast(IsHighRisk as int) as IsHighRisk, cast(IsNamedException as int) as IsNamedException, cast(ChargeOnRedeem as int) as ChargeOnRedeem, IsOnlineOnly, IsPremiumRetailer
					into #Brand
					from warehouse.relational.Brand b

					insert into #Brand(BrandID, BrandName, IsLivePartner, BrandGroupID, SectorID, IsHighRisk, IsNamedException, ChargeOnRedeem, IsOnlineOnly, IsPremiumRetailer) 
								values (@BrandID_WRJL, 'COMBO_WaitroseJohnLewis', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL)

					create clustered index INX on #Brand(brandid)

					

					-- Partner table
					If Object_ID('tempdb..#Partner') Is Not Null Drop Table #Partner
					select *
					into #Partner
					from warehouse.relational.Partner b

					insert into #Partner
								values (NULL, 1000008, 'COMBO_WaitroseJohnLewis', @BrandID_WRJL, 'COMBO_WaitroseJohnLewis', 1, NULL, 1)

					create clustered index INX on #Partner(brandid)

   				    -- Consumercombination table
					If Object_ID('tempdb..#ConsumerCombination') Is Not Null Drop Table #ConsumerCombination
					select 
					cast(ConsumerCombinationID as int) as ConsumerCombinationID,
					cast(BrandID as int) as BrandID
					into #ConsumerCombination
					from warehouse.relational.ConsumerCombination cc
					where
					exists (select 1 from #Partner p where p.BrandID = cc.BrandID)

					insert into #ConsumerCombination
					select ConsumercombinationID, @BrandID_WRJL
					from warehouse.relational.ConsumerCombination
					where
					brandid in (234, 485)

					create clustered index INX on #ConsumerCombination(ConsumerCombinationID)

					If Object_ID('tempdb..#BrandComp') Is Not Null Drop Table #BrandComp
					select cast (ID as int) as ID, BrandID, CompetitorBrandID, StartDate, EndDate
					into #BrandComp
					from Warehouse.Lion.BOPE_BrandCompetitor

					insert into #BrandComp(ID, BrandID, CompetitorBrandID, StartDate, EndDate) values (-1, @BrandID_WRJL, 11, '2019-01-01', NULL)
					insert into #BrandComp(ID, BrandID, CompetitorBrandID, StartDate, EndDate) values (-1, @BrandID_WRJL, 425, '2019-01-01', NULL)
					insert into #BrandComp(ID, BrandID, CompetitorBrandID, StartDate, EndDate) values (-1, @BrandID_WRJL, 292, '2019-01-01', NULL)
					insert into #BrandComp(ID, BrandID, CompetitorBrandID, StartDate, EndDate) values (-1, @BrandID_WRJL, 274, '2019-01-01', NULL)




				/*******************************************************************************
						1.1.1. Fetch list of all live Redmeption Items
				*******************************************************************************/

					--	The case when is used to facilitate the BA proxy for AVIOS.
					
					If Object_ID('tempdb..#VoucherSetUp_All') Is Not Null Drop Table #VoucherSetUp_All
					Select DISTINCT
						   ri.RedemptionPartnerGUID AS PartnerID
                         , ri.RetailerName AS PartnerName
						 , p.BrandID 
						 , ri.RedemptionOfferGUID AS RedeemID
						 , ri.Amount as MinCBreq
						 , Dense_Rank() Over (Order by ri.Amount Asc) as MinCBreq_Rank
					Into #VoucherSetUp_All
					From [WH_VirginPCA].[Derived].[RedemptionItems] ri
					Inner join #Partner p
						on p.PartnerName = ri.RetailerName 
					Where ri.Status = 'Live'


				/*******************************************************************************
						1.1.2. Fetch min req spend per Redemption Item and designate jokers
				*******************************************************************************/

						/*******************************************************************************
								1.1.2.1. Convert @JokerSlotPartners_CommaSeperated to temp table
						*******************************************************************************/

							If Object_ID('tempdb..#JokerPartners') Is Not Null Drop Table #JokerPartners
							Create Table #JokerPartners (PartnerID Int)
							INSERT INTO #JokerPartners
							SELECT Item AS PartnerID
							FROM [Warehouse].[dbo].[il_SplitDelimitedStringArray] (@JokerSlotPartners_CommaSeperated, ',')


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
				 , cu.CashbackAvailable AS ClubCashAvailable
				 , nlsc.LionSendID
			Into #Customers
			From [Derived].Customer cu
			Inner join [Email].[NominatedLionSendComponent] nlsc
				on cu.CompositeId = nlsc.CompositeId
			Left join [Derived].[CINList] cl
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
					From #ConsumerCombination cc
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
								  Inner join [Trans].[ConsumerTransaction] m 
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
					From #ConsumerCombination cc
					Inner join #BrandComp bc 
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
								  Inner join [Trans].[ConsumerTransaction] m 
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
				 , MAX(Case
						When bp.CINID Is Null Then 0
						Else 1
				   End) as BrandShop
				 , MAX(Case
						When sp.CINID Is Null Then 0
						Else 1
				   End) as SectorShop
				 , MAX(Case
						When vs.BrandID Is Null Then 0
						Else 1
				   End) as CBavailable
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
			GROUP BY fbc.BrandID
				 , fbc.FanID
				 , fbc.CINID
				 , fbc.ClubCashAvailable

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
			Inner join #Brand br
				on bp.BrandID = br.BrandID
				

		/***************************************************************************************************
				2.2. Select slots 1-4 Where available and fill in blanks with priority table
					 The fith slot is saved for cases where there is a joker redemption item present
		***************************************************************************************************/
		
			Declare @JokerRetailerPresent INT = 0

			If (Select Count(1) From #VoucherSetUp Where SlotType = 'JokerSlot') != 0 Set @JokerRetailerPresent = (SELECT COUNT(*) FROM #JokerPartners)

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
						  Left join Warehouse.Lion.BOPE_BrandCommercialRank cr
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

					If (@JokerRetailerPresent > 0)
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



		/***************************************************************************************************
				2.5. Force Push Cineworld and Greggs offers to those customers who - 
				(a)	live 30 mins from Cineworld (push Cineworld)
				(b) are not Premier cusotmers	(push Greggs)
		***************************************************************************************************/

				/**************************************************************************************************
						2.5.1. Greggs Force
						
						Note:
						- If the customer is a Premier, Greggs voucher may still appear in their assigned Burn
						offers, however at the rank naturally assigned according to standard logic.
				****************************************************************************************************/
																
							/**********************************************************************************
									2.5.1.1. Select FanIDs of Customers that are NOT Premier customers
							***********************************************************************************/

							IF OBJECT_ID ('tempdb..#Premier') IS NOT NULL DROP TABLE #Premier;
							SELECT		FanID
							INTO		#Premier
							FROM		Derived.Customer_LoyaltySegment
							WHERE		CustomerSegment = 'V'
							AND			EndDate IS NULL
							CREATE CLUSTERED INDEX ind_fan ON #Premier(FanID)

							-- 297,193 premier
							
							
							/***********************************************************************************************
									2.5.1.2. Remove Premier  in the event that it has already been assigned to a customer,
									increment RANK on all redemptions by +1, and slide Greggs in with Rank = 1 
							************************************************************************************************/

							-- this table is created for efficiency reasons later on
							If Object_ID('tempdb..#Allocated_Retailers_Greggs_PremierOrControlGroup') Is Not Null Drop Table #Allocated_Retailers_Greggs_PremierOrControlGroup
							SELECT		t1.FanID, t1.BrandID, t1.[Rank], t1.InputType
							INTO		#Allocated_Retailers_Greggs_PremierOrControlGroup
							FROM		#Allocated_Retailers t1
							WHERE EXISTS (	SELECT 1
											FROM #Premier pr
											WHERE t1.FanID = pr.FanID)

							CREATE CLUSTERED INDEX ind_fan ON #Allocated_Retailers_Greggs_PremierOrControlGroup(FanID)
							
							If Object_ID('tempdb..#Allocated_Retailers_Greggs_ToUpdate') Is Not Null Drop Table #Allocated_Retailers_Greggs_ToUpdate
							SELECT		t1.FanID, t1.BrandID, t1.[Rank], t1.InputType
							INTO		#Allocated_Retailers_Greggs_ToUpdate
							FROM		#Allocated_Retailers t1
							WHERE		BrandID != 914	-- Greggs
							AND NOT EXISTS (SELECT 1
											FROM #Premier pr
											WHERE t1.FanID = pr.FanID)

							CREATE CLUSTERED INDEX ind_fan ON #Allocated_Retailers_Greggs_ToUpdate(FanID) WITH (FILLFACTOR = 80)
							
							-- Increase Rank for all Offers
							UPDATE		#Allocated_Retailers_Greggs_ToUpdate
							SET			[Rank] = [Rank] + 1

							-- Force in Greggs offer @ Rank 1

							;WITH
							CustomersToInsert AS (	SELECT	DISTINCT
															FanID
													FROM #Allocated_Retailers_Greggs_ToUpdate)
													
							INSERT INTO #Allocated_Retailers_Greggs_ToUpdate(FanID, BrandID, [Rank], InputType)
							SELECT		FanID, 914, 1, '0. Forced'
							FROM		CustomersToInsert
							WHERE EXISTS (	SELECT 1
											FROM #VoucherSetUp_All
											WHERE BrandID = 914)


							-- Merge offers from Customers who got Greggs forced, and Customers who did not get Greggs forced
							If Object_ID('tempdb..#Allocated_Retailers_Greggs_forced') Is Not Null Drop Table #Allocated_Retailers_Greggs_forced
							SELECT		FanID, BrandID, [Rank], InputType
							INTO		#Allocated_Retailers_Greggs_forced
								FROM	#Allocated_Retailers_Greggs_PremierOrControlGroup
							UNION ALL
							SELECT		FanID, BrandID, [Rank], InputType
								FROM	#Allocated_Retailers_Greggs_ToUpdate

							CREATE CLUSTERED INDEX indx_Fan ON #Allocated_Retailers_Greggs_forced(FanID)


				/**************************************************************************************************
						2.5.2. Cineworld Force
						
						Note:
						- If the customer does not live within 30 mins, Cineworld voucher may still appear in
						their assigned Burn offers, however at the rank naturally assigned according to
						standard logic.
				****************************************************************************************************/
				
							/**********************************************************************************
									2.5.2.1. Select FanIDs of Customers that live within 30 mins of Cineworld
							***********************************************************************************/

							--If Object_ID('tempdb..#CineworldProximityCustomers') Is Not Null Drop Table #CineworldProximityCustomers;
							--WITH	cineworld_postcodes AS (
							--		SELECT	LEFT(PostCode, (LEN(PostCode) - 2)) AS CineworldPostSector
							--		FROM	AWSFile.ComboPostCode p
							--		JOIN	warehouse.relational.ConsumerCombination c ON c.ConsumerCombinationID = p.ConsumerCombinationID
							--		WHERE	BrandID = 85
							--	),	postcodes_less30mins_cineworld AS (
							--		SELECT	DISTINCT REPLACE(ToSector, ' ', '') AS CustomerPostSector
							--		FROM	warehouse.relational.DriveTimeMatrix d with (nolock)
							--		JOIN	cineworld_postcodes cp ON cp.CineworldPostSector = REPLACE(d.FromSector, ' ', '')
							--		WHERE	DriveTimeMins <= 30
							--			-- 30 mins = 2,184,199
							--			-- 45 mins = 2,453,539
							--	)
							--SELECT		DISTINCT FanID
							--INTO		#CineworldProximityCustomers
							--FROM		warehouse.relational.Customer c
							--WHERE		REPLACE(PostalSector, ' ', '') IN (SELECT DISTINCT CustomerPostSector FROM postcodes_less30mins_cineworld)
							--AND NOT EXISTS (SELECT 1
							--				FROM Lion.BOPEForceIN_ControlGroup_20201008 bcg
							--				WHERE c.FanID = bcg.FanID)
							--CREATE CLUSTERED INDEX ind_fan ON #CineworldProximityCustomers(FanID)




							--/***********************************************************************************************
							--		2.5.2.2. Remove Cineworld in the event that it has already been assigned to a customer,
							--		increment RANK on all redemptions by +1, and slide Cineworld in with Rank = 1 
							--************************************************************************************************/

							--If Object_ID('tempdb..#Allocated_Retailers_CPC_only') Is Not Null Drop Table #Allocated_Retailers_CPC_only
							--SELECT		t1.BrandID, t1.FanID, t1.[Rank], t1.InputType
							--INTO		#Allocated_Retailers_CPC_only
							--FROM		#Allocated_Retailers_Greggs_forced t1
							--JOIN		#CineworldProximityCustomers cpc ON cpc.FanID = t1.FanID
							--WHERE		BrandID != 85	-- Cineworld
							--CREATE CLUSTERED INDEX ind_fan ON #Allocated_Retailers_CPC_only(FanID)

							---- this table is created for efficiency reasons later on
							--If Object_ID('tempdb..#Allocated_Retailers_not_CPC') Is Not Null Drop Table #Allocated_Retailers_not_CPC
							--SELECT		t1.FanID, t1.BrandID, t1.[Rank], t1.InputType
							--INTO		#Allocated_Retailers_not_CPC
							--FROM		#Allocated_Retailers_Greggs_forced t1
							--LEFT JOIN	#CineworldProximityCustomers t2 ON t2.FanID = t1.FanID
							--WHERE		t2.FanID IS NULL
							--CREATE CLUSTERED INDEX ind_fan ON #Allocated_Retailers_not_CPC(FanID)
							
							---- Increase Rank for all Offers
							--UPDATE		#Allocated_Retailers_CPC_only
							--SET			[Rank] = [Rank] + 1

							---- Force in Cineworld offer @ Rank 1
							--INSERT INTO #Allocated_Retailers_CPC_only(FanID, BrandID, [Rank], InputType)
							--SELECT		DISTINCT FanID, 85, 1, '0. Forced'
							--FROM		#Allocated_Retailers_CPC_only

							---- Merge offers from Customers who got Cineworld forced, and Customers who did not get Cineworld forced
							--If Object_ID('tempdb..#Allocated_Retailers_CineworldGreggs_forced') Is Not Null Drop Table #Allocated_Retailers_CineworldGreggs_forced
							--SELECT		FanID, BrandID, [Rank], InputType
							--INTO		#Allocated_Retailers_CineworldGreggs_forced
							--	FROM	#Allocated_Retailers_not_CPC
							--UNION
							--SELECT		FanID, BrandID, [Rank], InputType
							--	FROM	#Allocated_Retailers_CPC_only
							--CREATE CLUSTERED INDEX indx_Fan ON #Allocated_Retailers_CineworldGreggs_forced(FanID)
							


				/***********************************************************************************************
						2.5.3. Limit to top 5 Brands, according to 'input type' and 'rank'
				************************************************************************************************/

						If Object_ID('tempdb..#Allocated_Retailers_f') Is Not Null Drop Table #Allocated_Retailers_f
						SELECT	FanID, BrandID, [Rank], InputType
						INTO	#Allocated_Retailers_f
						FROM	(	SELECT	FanID, BrandID, [Rank], InputType
										,	row_number() OVER (PARTITION BY FanID ORDER BY InputType Asc, [Rank] Asc) AS new_rank
									FROM	#Allocated_Retailers_Greggs_forced
								) a
						WHERE	new_rank <= 5



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
				 , rv.LionSendID
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
					   , cu.LionSendID
				  	   , Row_Number() Over (Partition by ar.FanID, ar.BrandID Order by MinCBreq desc) as ID
				  From #Allocated_Retailers_f ar
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
		
			ALTER INDEX [IUX_LSIDOfferTypeCompRank] ON [Email].[NominatedLionSendComponent_RedemptionOffers] DISABLE

			Truncate Table [Email].[NominatedLionSendComponent_RedemptionOffers]
			Insert Into [Email].[NominatedLionSendComponent_RedemptionOffers] (	LionSendID
																			,	CompositeID
																			,	TypeID
																			,	ItemRank
																			,	ItemID)
			Select LionSendID
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
				
			ALTER INDEX [IUX_LSIDOfferTypeCompRank] ON [Email].[NominatedLionSendComponent_RedemptionOffers] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 90, SORT_IN_TEMPDB = ON)
			UPDATE STATISTICS [Email].[NominatedLionSendComponent_RedemptionOffers]

End







