/*
Grabs CTLoad_MIDIHolding and CreditCardLoad_MIDIHolding into CTLoad_MIDINewCombo_v2 and then
Cleanses narrative, suggests brand. 
Data remains in CTLoad_MIDINewCombo_v2 for manual processing.
*/
CREATE PROCEDURE [gas].[CTLoad_Module5_MIDI]

AS

SET NOCOUNT ON

	-------------------------------------------------------------------------------------------------------------------
	-- Clear brand suggestions	gas.CTLoad_BrandSuggestions_Clear		
	-------------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_V2
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_Branded
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_BrandMatch
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_PossibleBrands
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_DataMining
	TRUNCATE TABLE Staging.CreditCardLoad_MIDIHolding_Combos


	

	-------------------------------------------------------------------------------------------------------------------
	-- Load CTLoad_MIDINewCombo	Data flow task	Staging.CTLoad_GetNewCombos  Staging.CTLoad_MIDIHolding	 Staging.CTLoad_MIDINewCombo
	-------------------------------------------------------------------------------------------------------------------
	INSERT INTO Staging.CTLoad_MIDINewCombo_v2 (MID, Narrative, LocationCountry, MCCID, OriginatorID, IsCreditOrigin)
	SELECT MID, Narrative, LocationCountry, MCCID, OriginatorID, CAST(0 AS BIT) AS IsCreditOrigin
	FROM staging.CTLoad_MIDIHolding WITH (NOLOCK)
	WHERE ConsumerCombinationID IS NULL
	UNION
	SELECT MID, Narrative, LocationCountry, MCCID, OriginatorReference AS OriginatorID, CAST(1 AS BIT) AS IsCreditOrigin
	FROM Staging.CreditCardLoad_MIDIHolding WITH (NOLOCK)
	WHERE ConsumerCombinationID IS NULL



	-------------------------------------------------------------------------------------------------------------------
	-- Suggest brands	gas.CTLoad_MIDINewCombo_SuggestBrands		
	-- EXEC gas.CTLoad_MIDINewCombo_SuggestBrands_V3
	-------------------------------------------------------------------------------------------------------------------

	If Object_ID('tempdb..#Narrative_Cleaned') Is Not Null Drop Table #Narrative_Cleaned
	Select mnc.ID as MIDINewComboID
		 , LTrim(RTrim(Replace(Replace(Replace(mnc.Narrative, ' ', '<>'), '><', ''), '<>', ' '))) as Narrative_Cleaned
		 , 0 as IsPrefixRemoved
	Into #Narrative_Cleaned
	From Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc


	Declare @LoopNumber Int = (Select Min(ID) From Warehouse.Staging.CTLoad_MIDINarrativeCleanup Where LiveRule = 1)
		  , @LoopEnd Int = (Select Max(ID) From Warehouse.Staging.CTLoad_MIDINarrativeCleanup Where LiveRule = 1)
		  , @TextToReplace VarChar(15)
		  , @TextToReplace_NoSpaces VarChar(15)
		  , @TextToReplaceJoin VarChar(15)
		  , @TextToReplaceJoin_NoSpaces VarChar(15)
		  , @NarrativeNotLike VarChar(15)
		  , @IsPrefixRemoved Bit

	While @LoopNumber <= @LoopEnd
	Begin

			Select @TextToReplace = Replace(TextToReplace, '%', '')
				 , @TextToReplacejoin = TextToReplace
				 , @TextToReplace_NoSpaces = Replace(Replace(TextToReplace, '%', ''), ' ', '')
				 , @TextToReplacejoin_NoSpaces = Replace(TextToReplace, ' ', '')
				 , @NarrativeNotLike = NarrativeNotLike
				 , @IsPrefixRemoved = IsPrefixRemoved
			From Warehouse.Staging.CTLoad_MIDINarrativeCleanup
			Where ID = @LoopNumber


			Update nc
			Set Narrative_Cleaned = nc_2.Narrative_Cleaned
			  , IsPrefixRemoved = @IsPrefixRemoved
			From #Narrative_Cleaned nc
			Cross apply (Select Case
									When (Narrative_Cleaned Like @TextToReplacejoin Or Narrative_Cleaned Like @TextToReplacejoin_NoSpaces) And Narrative_Cleaned Not Like @NarrativeNotLike
											Then LTrim(RTrim(Replace(Replace(Replace(Replace(Replace(Narrative_Cleaned, @TextToReplace, ''), @TextToReplace_NoSpaces, ''), ' ', '<>'), '><', ''), '<>', ' ')))
									Else Narrative_Cleaned
								End as Narrative_Cleaned) nc_1
			Cross apply (Select Case
									When Left(nc_1.Narrative_Cleaned, 1) In ('-', '*') 
											Then Ltrim(Right(nc_1.Narrative_Cleaned, Len(nc_1.Narrative_Cleaned) - 1))
									Else nc_1.Narrative_Cleaned
								End as Narrative_Cleaned) nc_2
			Where (nc.Narrative_Cleaned Like @TextToReplacejoin Or nc.Narrative_Cleaned Like @TextToReplacejoin_NoSpaces)
			And nc.Narrative_Cleaned Not Like @NarrativeNotLike

			Select @LoopNumber = Min(ID)
			From Warehouse.Staging.CTLoad_MIDINarrativeCleanup
			Where ID > @LoopNumber
			And LiveRule = 1

	End

	Update mnc
	Set mnc.Narrative_Cleaned = nc.Narrative_Cleaned
	  , mnc.IsPrefixRemoved = nc.IsPrefixRemoved
	From Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	Inner join #Narrative_Cleaned nc
		on mnc.ID = nc.MIDINewComboID


	--Prefix, MID, MCC, Country, Originator/Acquirer

		If Object_ID('tempdb..#PossibleBrandsTemp1') Is Not Null Drop Table #PossibleBrandsTemp1
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp1
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where m.OriginatorID != ''
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 1 as MatchTypeID
		From #PossibleBrandsTemp1 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.MID = cc.MID
			And pbt.LocationCountry = cc.LocationCountry
			And pbt.MCCID = cc.MCCID
		Left join MI.MOMCombinationAcquirer a
			On pbt.AcquirerID = A.AcquirerID
			And cc.ConsumerCombinationID = A.ConsumerCombinationID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And (pbt.OriginatorID = cc.OriginatorID OR a.AcquirerID IS Not NULL)
		And Len(pbt.MID) > 0


	--Prefix, MID, Country, Originator/Acquirer

		If Object_ID('tempdb..#PossibleBrandsTemp2') Is Not Null Drop Table #PossibleBrandsTemp2
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp2
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like bm.Narrative
		Where m.OriginatorID != ''
		And Not Exists (Select 1
						From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						Where p.ComboID = m.ID)
						
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			   pbt.MIDINewCombo
			 , pbt.BrandID
			 , 2 as MatchTypeID
		From #PossibleBrandsTemp2 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.MID = cc.MID
			And pbt.LocationCountry = cc.LocationCountry
		Left join MI.MOMCombinationAcquirer a
			On pbt.AcquirerID = A.AcquirerID
			And cc.ConsumerCombinationID = A.ConsumerCombinationID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And (pbt.OriginatorID = cc.OriginatorID OR a.AcquirerID IS Not NULL)
		And Len(pbt.MID) > 0


	--Prefix, MCC, Country, Originator/Acquirer

		If Object_ID('tempdb..#PossibleBrandsTemp3') Is Not Null Drop Table #PossibleBrandsTemp3
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp3
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where m.OriginatorID != ''
		And Not Exists (Select 1
						From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						Where p.ComboID = m.ID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 3 as MatchTypeID
		From #PossibleBrandsTemp3 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.LocationCountry = cc.LocationCountry
			And pbt.MCCID = cc.MCCID
		Left join MI.MOMCombinationAcquirer a
			On pbt.AcquirerID = A.AcquirerID
			And cc.ConsumerCombinationID = A.ConsumerCombinationID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And (pbt.OriginatorID = cc.OriginatorID OR a.AcquirerID IS Not NULL)


	--Prefix, MID, MCC, Country

		If Object_ID('tempdb..#PossibleBrandsTemp4') Is Not Null Drop Table #PossibleBrandsTemp4
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp4
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where Not Exists (Select 1
						  From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						  Where p.ComboID = m.ID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 4 as MatchTypeID
		From #PossibleBrandsTemp4 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.LocationCountry = cc.LocationCountry
			And pbt.MCCID = cc.MCCID
			And pbt.MID = cc.MID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And Len(pbt.MID) > 0


	--Prefix, MCC, Country

		If Object_ID('tempdb..#PossibleBrandsTemp5') Is Not Null Drop Table #PossibleBrandsTemp5
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp5
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where Not Exists (Select 1
						  From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						  Where p.ComboID = m.ID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 5 as MatchTypeID
		From #PossibleBrandsTemp5 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.LocationCountry = cc.LocationCountry
			And pbt.MCCID = cc.MCCID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal


	--Prefix, MID, Country

		If Object_ID('tempdb..#PossibleBrandsTemp6') Is Not Null Drop Table #PossibleBrandsTemp6
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp6
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where Not Exists (Select 1
						  From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						  Where p.ComboID = m.ID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 6 as MatchTypeID
		From #PossibleBrandsTemp6 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.LocationCountry = cc.LocationCountry
			And pbt.MID = cc.MID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And Len(pbt.MID) > 0

		
	--Prefix, MCC

		If Object_ID('tempdb..#PossibleBrandsTemp7') Is Not Null Drop Table #PossibleBrandsTemp7
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp7
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where Not Exists (Select 1
						  From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						  Where p.ComboID = m.ID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 7 as MatchTypeID
		From #PossibleBrandsTemp7 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.MCCID = cc.MCCID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		
		
	--MID, MCC

		If Object_ID('tempdb..#PossibleBrandsTemp8') Is Not Null Drop Table #PossibleBrandsTemp8
		Select m.ID as MIDINewCombo
			 , m.MID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
		Into #PossibleBrandsTemp8
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Where Not Exists (Select 1
						  From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						  Where p.ComboID = m.ID)

		If Object_ID('tempdb..#SharedMIDs') Is Not Null Drop Table #SharedMIDs
		Select Distinct 
				MID
			  , MCCID
		Into #SharedMIDs
		From Warehouse.Relational.ConsumerCombination cc
		Where BrandID in (1293, 943, 944)
		Or Narrative Like '%CRV%*%'
		Or Narrative Like '%PP%*%'
		Or Narrative Like '%PayPal%*%'

		Create Clustered Index CIX_SharedMIDs_MIDMCCID On #SharedMIDs (MID)
		
		If Object_ID('tempdb..#MIDsMultipleBrands') Is Not Null Drop Table #MIDsMultipleBrands
		Select cc.MID
			 , cc.MCCID
			 , Count(Distinct BrandID) as BrandIDs
		Into #MIDsMultipleBrands
		From Warehouse.Relational.ConsumerCombination cc
		Where Not Exists (Select 1
						  From #SharedMIDs sm
						  Where cc.MID = sm.MID
						  And cc.MCCID = sm.MCCID)
		Group by cc.MID
			   , cc.MCCID
		
		Create Clustered Index CIX_MIDsMultipleBrands_MIDMCCID On #MIDsMultipleBrands (MID, MCCID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, cc.BrandID
			, 8 as MatchTypeID
		From #PossibleBrandsTemp8 pbt
		Inner join Relational.ConsumerCombination cc
			On pbt.MCCID = cc.MCCID
			And pbt.MID = cc.MID
		Inner join Warehouse.Relational.Brand br
			on cc.BrandID = br.BrandID
		Left join #MIDsMultipleBrands mmb
			on pbt.MID = mmb.MID
			and pbt.MCCID = mmb.MCCID
		Where cc.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
		And Len(pbt.MID) > 0
		And cc.BrandID not in (944, 943)
		And Case When cc.BrandID = 1224 And Narrative_Cleaned Not Like '%sl%w%' Then 1 End Is Null
		And ((BrandIDs Is Not Null And (Narrative_Cleaned Like '%' + Left(BrandName, 1) + '%' Or BrandName Like '%' + Left(Narrative_Cleaned, 2) + '%'))
		Or (BrandIDs Is Not Null And (Narrative_Cleaned Like '%' + Left(BrandName, 2) + '%' Or BrandName Like '%' + Left(Narrative_Cleaned, 3) + '%')))


	--Prefix ONLY

		If Object_ID('tempdb..#PossibleBrandsTemp9') Is Not Null Drop Table #PossibleBrandsTemp9
		Select m.ID as MIDINewCombo
			 , m.MID
			 , bm.BrandID
			 , m.LocationCountry
			 , m.MCCID
			 , m.AcquirerID
			 , m.OriginatorID 
			 , m.IsPrefixRemoved
			 , m.Narrative
			 , m.Narrative_Cleaned
			 , bm.Narrative as MatchedOn
		Into #PossibleBrandsTemp9
		From Warehouse.Staging.CTLoad_MIDINewCombo_v2 m
		Inner join Staging.BrandMatch bm 
			On m.Narrative_Cleaned Like BM.Narrative
		Where Not Exists (Select 1
						  From Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands p
						  Where p.ComboID = m.ID)
		 
		Insert Into Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands (ComboID
																		  , SuggestedBrandID
																		  , MatchTypeID)
		Select Distinct
			  pbt.MIDINewCombo
			, pbt.BrandID
			, 9 as MatchTypeID
		From #PossibleBrandsTemp9 pbt
		

	----LOAD TEXT MATCHES
	--INSERT INTO Staging.CTLoad_MIDINewCombo_BrandMatch(ComboID, BrandMatchID, BrandID, BrandGroupID)
	--SELECT DISTINCT M.ID, BM.BrandMatchID, BM.BrandID, B.BrandGroupID
	--FROM Staging.CTLoad_MIDINewCombo M
	--INNER JOIN Staging.BrandMatch bm ON M.Narrative LIKE BM.Narrative
	--INNER JOIN Relational.Brand b ON bm.BrandID = b.BrandID


	--UPDATE INFORMATION IN MATCH TABLE
	--EXEC gas.CTLoad_MIDINewCombo_UpdateMatchInfo_V2
	If Object_ID('tempdb..#CTLoad_MIDINewCombo_PossibleBrands_MinMatchType') Is Not Null Drop Table #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType
	Select ID
		 , ComboID
		 , SuggestedBrandID
		 , MatchTypeID
		 , BrandProbability
	Into #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType
	From (Select ID
			   , ComboID
			   , SuggestedBrandID
			   , MatchTypeID
			   , BrandProbability
			   , Min(MatchTypeID) Over (Partition by ComboID) as MinMatchTypeID
		  FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands pb) mpb
	Where MatchTypeID = MinMatchTypeID

	UPDATE mnc
	SET SuggestedBrandID = pbm.SuggestedBrandID
	  , MatchType = pbm.MatchTypeID
	  , BrandProbability = pbm.BrandProbability
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType pbm
		ON mnc.ID = pbm.ComboID
	WHERE mnc.SuggestedBrandID IS NULL

	If Object_ID('tempdb..#CTLoad_MIDINewCombo_PossibleBrands_MatchCount') Is Not Null Drop Table #CTLoad_MIDINewCombo_PossibleBrands_MatchCount
	Select ComboID
		 , COUNT(1) AS MatchCount
	Into #CTLoad_MIDINewCombo_PossibleBrands_MatchCount
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands
	WHERE SuggestedBrandID != 943
	AND SuggestedBrandID != 944
	GROUP BY ComboID
	HAVING COUNT(1) > 1

	UPDATE mnc
	SET MatchCount = pbmc.MatchCount
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #CTLoad_MIDINewCombo_PossibleBrands_MatchCount pbmc
		ON mnc.ID = pbmc.ComboID
	WHERE SuggestedBrandID != 943
	AND SuggestedBrandID != 944

	
	----Mark the rest as unbranded
	UPDATE mnc
	SET SuggestedBrandID = 944
	  , MatchType = 11
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	WHERE SuggestedBrandID IS NULL

	--match paypal
	UPDATE mnc
	SET SuggestedBrandID = 943
	  , MatchType = 10
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	WHERE (Narrative LIKE '%PAYPAL%') -- OR Narrative LIKE 'PP*%')
	AND (SuggestedBrandID = 944 Or MatchType = 9)

	--match iZettle
	UPDATE Warehouse.Staging.CTLoad_MIDINewCombo_v2
	SET SuggestedBrandID = 1293
	  , MatchType = 14
	WHERE Narrative Like '%IZ *%'
	AND (SuggestedBrandID = 944 Or MatchType = 9)

	--CHANGE SUGGESTED BRAND IDs ACCORDING TO EXCEPTIONS

	UPDATE mnc
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN Staging.MIDIBrandChange_MCC mc
		ON mnc.SuggestedBrandID = mc.BrandIDInitial
		AND mnc.MCCID = mc.MCCID

	UPDATE mnc
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN Staging.MIDIBrandChange_Narrative mc
		ON mnc.SuggestedBrandID = mc.BrandIDInitial
		AND mnc.Narrative_Cleaned LIKE mc.Narrative

RETURN 0