
/**********************************************************************

	Author:		 Rory Francis
	Create date: 2018-03-15
	Description: Automating Offer Prioritisation Engine checks

	======================= Change Log =======================


***********************************************************************/

CREATE PROCEDURE [Email].[Newsletter_OfferPrioritisation_Validation] (@Date Date)
	
As

Begin

	Declare @EmailDate Date = @Date

	--Declare @EmailDate Date = '2021-02-25'

	/*******************************************************************************************************************************************
		1. Prepare tables for validation
	*******************************************************************************************************************************************/

		DECLARE @ClubID INT = 166

		If Object_ID('tempdb..#IronOffer') Is Not Null Drop Table #IronOffer
		SELECT *
		INTO #IronOffer
		FROM [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
		WHERE EXISTS (	SELECT 1
						FROM [DIMAIN_TR].[SLC_REPL].[dbo].[IronOfferClub] ioc
						WHERE iof.ID = ioc.IronOfferID
						AND ioc.ClubID = @ClubID)
		
		--DELETE
		--FROM #IronOffer
		--WHERE StartDate < @EmailDate
		--AND IsSignedOff = 0

		/***********************************************************************************************************************
			1.1. Create empty table for offer with errors
		***********************************************************************************************************************/

			If Object_ID('tempdb..#Newsletter_OfferPrioritisation_Errors') Is Not Null Drop Table #Newsletter_OfferPrioritisation_Errors
			Create Table #Newsletter_OfferPrioritisation_Errors (IronOfferID Int Not Null
														 , IronOfferName nVarChar(200) Null
														 , StartDate DateTime Null
														 , EndDate DateTime NULL
														 , PartnerID Int NULL
														 , NewOffer VarChar(14) NULL
														 , Duplicated Int Default 0
														 , EndBeforeCycleEnds Int Default 0
														 , StartAfterCycleStart Int Default 0
														 , OfferMissingFromOPE Int Default 0
														 , OfferInOPENotInIronOffer Int Default 0
														 , OfferInOPEMissingFromSelections Int Default 0
														 , OfferInSelectionsMissingFromOPE Int Default 0)
													 
													 
		/***********************************************************************************************************************
			1.2. Remove null rows from SSIS import table
		***********************************************************************************************************************/

			Delete
			From [Email].[Newsletter_OfferPrioritisation_Import]
			Where [Email].[Newsletter_OfferPrioritisation_Import].[IronOfferID] Is Null
			And [Email].[Newsletter_OfferPrioritisation_Import].[PartnerName] Is Null
													 

		/***********************************************************************************************************************
			1.3. Generate weighting for all offers
		***********************************************************************************************************************/

			IF Object_ID('tempdb..#OfferDetailsFromOPE') Is Not Null Drop Table #OfferDetailsFromOPE
			Select [eo].[IronOfferID] as OfferID
				 , 1001 - ROW_NUMBER() over (order by (select null)) as Weighting
				 , Case
						When [eo].[IronOfferName] like 'Core %' or [eo].[BaseOffer] like 'Core %' then 1
						Else 0
				   End as Base
			Into #OfferDetailsFromOPE
			From [Email].[Newsletter_OfferPrioritisation_Import] eo


	/*******************************************************************************************************************************************
		2. Split CampaignSetup_POS to offer level
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Fetch CampaignSetup_POS into temp table for campaigns with upcoming selection
		***********************************************************************************************************************/
		
			If Object_ID('tempdb..#CampaignSetup') Is Not Null Drop Table #CampaignSetup
			SELECT @EmailDate AS EmailDate
				 , [cs].[ClientServicesRef]
				 , iof.Item AS IronOfferID
			INTO #CampaignSetup
			FROM (SELECT [Selections].[CampaignSetup_POS].[ClientServicesRef]
				  	   , [Selections].[CampaignSetup_POS].[OfferID]
				  FROM [Selections].[CampaignSetup_POS]
				  WHERE @EmailDate BETWEEN [Selections].[CampaignSetup_POS].[StartDate] And [Selections].[CampaignSetup_POS].[EndDate]) cs
				  CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([cs].[OfferID], ',') iof
			WHERE iof.Item > 0


	/*******************************************************************************************************************************************
		3. For each possible error, add them to the previously created holding table with a flag of what those errors are
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Offers duplicated in the OPE
		***********************************************************************************************************************/

			IF Object_ID('tempdb..#OffersDuplicatedInOPE') Is Not Null Drop Table #OffersDuplicatedInOPE
			Select ope.OfferID as IronOfferID
				 , Min([ope].[Weighting]) as MinWeighting
			Into #OffersDuplicatedInOPE
			From #OfferDetailsFromOPE ope
			Group by ope.OfferID
			Having Count(1) > 1

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[Duplicated])
			Select i.ID as IronOfferID
				 , i.Name as IronOfferName
				 , i.StartDate
				 , i.EndDate
				 , i.PartnerID
				 , Case
						When i.StartDate = @EmailDate Then 1
						Else 0
				   End as NewOffer
				 , 1 as Duplicated
			From #OffersDuplicatedInOPE op
			Inner join #IronOffer i
				on op.IronOfferID=i.ID
			

		/***********************************************************************************************************************
			3.2. Offers going live that are not in the OPE
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[OfferMissingFromOPE])
			Select Distinct 
				   i.ID as IronOfferID
				 , i.Name as IronOfferName
				 , i.StartDate
				 , i.EndDate
				 , i.PartnerID
				 , Case
						When i.StartDate = @EmailDate Then 1
						Else 0
				   End as NewOffer
				 , 1 as OfferMissingFromOPE
			From #IronOffer i
			Where (@EmailDate between i.StartDate And i.EndDate Or i.EndDate is null)
			and i.IsAboveTheLine = 0
			and i.Name Not in ('suppressed','SPARE','SPARE!!!')
			and i.IsDefaultCollateral = 0
			and not exists (Select 1
							From #OfferDetailsFromOPE op
							Where #OfferDetailsFromOPE.[i].ID = op.OfferID)
			------ Constant Exclusions
			and i.PartnerID not in (4498,4497,4642)											-- Credit Cards
			and i.PartnerID not in (4648)													-- Direct Debit
			and i.PartnerID not in (Select #IronOffer.[PartnerID] from Warehouse.APW.PartnerAlternate)	-- Secondary Partner Recorda
			and i.ID not in (315,371,372,373,379,380,381,382,383,384,385,386,387,	-- Thomson & First Choice offers with last OfferMember date 2013-07-24
							  388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,
							  403,404,405,406,407,408,409,410,426,427,428,429,430,431,432,
							  433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,
							  448,449,450,451,452,453,454,455,456,457,458,459,460,515,528,
							  539,554,564,575,584,586,589,590,594,610,614,615,799,800,801,
							  802,803,1117,1590,1746,1748,1756,1758,1760,1761,1764,1768,
							  1772,1776,1778,1782,1786,1788,1790,1791,1793,1847,8612,
							  18289, 18290, 18295, 18296, 18297, 18298, 18299, 18300)
			


		/***********************************************************************************************************************
			3.3. Offers in the OPE that are not in IronOffer
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[OfferInOPENotInIronOffer])
			Select op.OfferID as IronOfferID
				 , 'Offer not found in IronOffer table' as IronOfferName
				 , Null as StartDate
				 , Null as EndDate
				 , Null as PartnerID
				 , Null as NewOffer
				 , 1 as OfferInOPENotInIronOffer
			From #OfferDetailsFromOPE op
			Where Not Exists (Select 1
							  From #IronOffer iof
							  Where #IronOffer.[op].OfferID = iof.ID)
			

		/***********************************************************************************************************************
			3.4. Offers ending before the cycle end date
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[EndBeforeCycleEnds])
			Select iof.ID as IronOfferID
				 , iof.Name as IronOfferName
				 , iof.StartDate as StartDate
				 , iof.EndDate as EndDate
				 , iof.PartnerID as PartnerID
				 , Case
						When iof.StartDate = @EmailDate Then 1
						Else 0
				   End as NewOffer
				 , 1 as EndBeforeCycleEnds
			From #OfferDetailsFromOPE as op
			Inner join #IronOffer iof
				on op.OfferID = iof.ID
			Where iof.EndDate < DateAdd(millisecond, -1003, DateAdd(day, 14, Convert(DateTime, @EmailDate)))
			

		/***********************************************************************************************************************
			3.5. Offers starting after the cycle start date
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[StartAfterCycleStart])
			Select iof.ID as IronOfferID
				 , iof.Name as IronOfferName
				 , iof.StartDate as StartDate
				 , iof.EndDate as EndDate
				 , iof.PartnerID as PartnerID
				 , Case
						When iof.StartDate = @EmailDate Then 1
						Else 0
				   End as NewOffer
				 , 1 as StartAfterCycleStart
			From #OfferDetailsFromOPE as op
			Inner join #IronOffer iof
				on op.OfferID = iof.ID
			Where iof.StartDate > @EmailDate
			

		/***********************************************************************************************************************
			3.6. Offers that are in the OPE but are not in the CampaignSetup_POS table 
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[OfferInOPEMissingFromSelections])
			Select op.OfferID as IronOfferID
				 , iof.Name as IronOfferName
				 , iof.StartDate as StartDate
				 , iof.EndDate as EndDate
				 , iof.PartnerID as PartnerID
				 , Case
						When iof.StartDate = @EmailDate Then 1
						Else 0
				   End as NewOffer
				 , 1 as OfferInOPEMissingFromSelections
			From #OfferDetailsFromOPE op
			Left join #IronOffer iof
				on op.OfferID = iof.ID
			Where Not Exists (Select 1
							  From #CampaignSetup cs
							  Where #CampaignSetup.[op].OfferID = cs.IronOfferID
							  Or #CampaignSetup.[op].Base = 1
							  Or #CampaignSetup.[op].OfferID = 14011)
			

		/***********************************************************************************************************************
			3.7. Offers that are in the CampaignSetup_POS table but are not in the OPE
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (#Newsletter_OfferPrioritisation_Errors.[IronOfferID]
														, #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
														, #Newsletter_OfferPrioritisation_Errors.[StartDate]
														, #Newsletter_OfferPrioritisation_Errors.[EndDate]
														, #Newsletter_OfferPrioritisation_Errors.[PartnerID]
														, #Newsletter_OfferPrioritisation_Errors.[NewOffer]
														, #Newsletter_OfferPrioritisation_Errors.[OfferInSelectionsMissingFromOPE])
			Select als.IronOfferID
				 , iof.Name as IronOfferName
				 , iof.StartDate as StartDate
				 , iof.EndDate as EndDate
				 , iof.PartnerID as PartnerID
				 , Case
						When iof.StartDate = @EmailDate Then 1
						Else 0
				   End as NewOffer
				 , 1 as OfferInSelectionsMissingFromOPE
			From #CampaignSetup als
			Left join #IronOffer iof
				on als.IronOfferID = iof.ID
			Where Not Exists (Select 1
							  From #OfferDetailsFromOPE op
							  Where op.OfferID = #OfferDetailsFromOPE.[als].IronOfferID)


	/*******************************************************************************************************************************************
		4. Combine all offers with errors are create single status column listing all errors per offer
	*******************************************************************************************************************************************/
	
		If Object_ID('tempdb..##Newsletter_OfferPrioritisation_Errors') Is Not Null Drop Table ##Newsletter_OfferPrioritisation_Errors
		Select [owe].[IronOfferID]
			 , [owe].[IronOfferName]
			 , [owe].[StartDate]
			 , [owe].[EndDate]
			 , [owe].[PartnerID]
			 , [owe].[NewOffer]
			 , Replace(Left([owe].[Status], Len([owe].[Status]) - 1), ', Offer', ',') as Status
		INTO ##Newsletter_OfferPrioritisation_Errors
		From (Select #Newsletter_OfferPrioritisation_Errors.[IronOfferID]
	  			   , #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
	  			   , #Newsletter_OfferPrioritisation_Errors.[StartDate]
	  			   , #Newsletter_OfferPrioritisation_Errors.[EndDate]
	  			   , #Newsletter_OfferPrioritisation_Errors.[PartnerID]
	  			   , #Newsletter_OfferPrioritisation_Errors.[NewOffer]
	  			   , Case When Max(#Newsletter_OfferPrioritisation_Errors.[Duplicated]) = 1 Then 'Offer duplicated in OPE, ' Else '' End
	  				 +
	  				 Case When Max(#Newsletter_OfferPrioritisation_Errors.[EndBeforeCycleEnds]) = 1 Then 'Offer ends before cycle ends, ' Else '' End
	  				 +
	  				 Case When Max(#Newsletter_OfferPrioritisation_Errors.[StartAfterCycleStart]) = 1 Then 'Offer starts after cycle starts, ' Else '' End
	  				 +
	  				 Case When Max(#Newsletter_OfferPrioritisation_Errors.[OfferMissingFromOPE]) = 1 Then 'Offer not listed in the OPE, ' Else '' End
	  				 +
	  				 Case When Max(#Newsletter_OfferPrioritisation_Errors.[OfferInOPENotInIronOffer]) = 1 Then 'Offer in the OPE but not found in IronOffer table, ' Else '' End
	  				 +
	  				 Case When Max(#Newsletter_OfferPrioritisation_Errors.[OfferInOPEMissingFromSelections]) = 1 Then 'Offer in the OPE but not set up for selection, ' Else '' End
	  				 +
	  				 Case When Max(#Newsletter_OfferPrioritisation_Errors.[OfferInSelectionsMissingFromOPE]) = 1 Then 'Offer set up for selection but not in the OPE, ' Else '' End as Status
			  From #Newsletter_OfferPrioritisation_Errors
			  Group by #Newsletter_OfferPrioritisation_Errors.[IronOfferID]
	  			   , #Newsletter_OfferPrioritisation_Errors.[IronOfferName]
	  			   , #Newsletter_OfferPrioritisation_Errors.[StartDate]
	  			   , #Newsletter_OfferPrioritisation_Errors.[EndDate]
	  			   , #Newsletter_OfferPrioritisation_Errors.[PartnerID]
	  			   , #Newsletter_OfferPrioritisation_Errors.[NewOffer]) owe

		UPDATE ##Newsletter_OfferPrioritisation_Errors
		SET ##Newsletter_OfferPrioritisation_Errors.[Status] = 'Offer not listed in the OPE'
		WHERE ##Newsletter_OfferPrioritisation_Errors.[Status] = 'Offer not listed in the OPE, set up for selection but not in the OPE'
				   

	/*******************************************************************************************************************************************
		5. Find all nFI offers
	*******************************************************************************************************************************************/
		
		If Object_ID('tempdb..#nFI_Offers') Is Not Null Drop Table #nFI_Offers
		Select Distinct iof.ID as IronOfferID
		Into #nFI_Offers
		From #IronOffer iof
		Inner join [DIMAIN_TR].[SLC_REPL].[dbo].[IronOfferClub] ioc
			on iof.ID = #IronOffer.[ioc].IronOfferID
		Where #IronOffer.[ClubID] Not In (166)
				   

	/*******************************************************************************************************************************************
		6. Insert all entries of OPE to a reviewd table, listing errors where applicable
	*******************************************************************************************************************************************/

		Delete owe
		From ##Newsletter_OfferPrioritisation_Errors owe
		Inner join #nFI_Offers nf
			on owe.IronOfferID = nf.IronOfferID
				   

	/*******************************************************************************************************************************************
		7. For permanent exclusions give the reason
	*******************************************************************************************************************************************/

		UPDATE owe
		SET owe.Status = owe.Status + ' - ' + pe.ExclusionReason
		FROM ##Newsletter_OfferPrioritisation_Errors owe
		INNER JOIN [Email].[OPE_PartnerExclusions] pe
			ON owe.PartnerID = pe.PartnerID
			AND @EmailDate BETWEEN pe.StartDate AND COALESCE(pe.EndDate, '9999-12-31')
		

	/*******************************************************************************************************************************************
		8. Insert all entries of OPE to a reviewd table, listing errors where applicable
	*******************************************************************************************************************************************/
	
	
		If Object_ID('tempdb..##OPE_Validation_Reviewed') Is Not Null Drop Table ##OPE_Validation_Reviewed
		Select Distinct
			   eo.PartnerName
			 , eo.AccountManager
			 , Coalesce(eo.ClientServicesRef, '') as ClientServicesRef
			 , eo.IronOfferName
			 , Coalesce(eo.OfferSegment, '') as OfferSegment
			 , eo.IronOfferID
			 , Coalesce(CONVERT(DECIMAL(19,2), eo.CashbackRate) * 100, CONVERT(DECIMAL(19,2), iof.TopCashBackRate)) as CashbackRate
			 , Coalesce(eo.BaseOffer, '') as BaseOffer
			 , Coalesce(opeerr.Status, '') as Status
			 , opew.Weighting
		INTO ##OPE_Validation_Reviewed
		From [Email].[Newsletter_OfferPrioritisation_Import] eo
		Inner join #OfferDetailsFromOPE opew
			on eo.IronOfferID = opew.OfferID
		Left Join ##Newsletter_OfferPrioritisation_Errors opeerr
			on opew.OfferID = opeerr.IronOfferID
		Left Join Warehouse.Relational.IronOffer iof
			on eo.IronOfferID = iof.IronOfferID

	/*******************************************************************************************************************************************
		9. Insert all entries of OPE to a reviewd table, listing errors where applicable
	*******************************************************************************************************************************************/

		Delete
		From [Email].[Newsletter_OfferPrioritisation]
		Where [Email].[Newsletter_OfferPrioritisation].[EmailDate] = @EmailDate

		INSERT INTO [Email].[Newsletter_OfferPrioritisation]
		Select #OfferDetailsFromOPE.[iof].PartnerID
			 , op.OfferID
			 , op.Weighting
			 , op.Base
			 , Case
					When #OfferDetailsFromOPE.[StartDate] >= GetDate() Or #OfferDetailsFromOPE.[StartDate] Is Null Then 1
					Else 0
			   End as NewOffer
			 , @EmailDate as EmailDate
		From #OfferDetailsFromOPE op
		Left join [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
			on op.OfferID = #OfferDetailsFromOPE.[iof].ID

	/*******************************************************************************************************************************************
		9. Insert all entries of OPE to a reviewd table, listing errors where applicable
	*******************************************************************************************************************************************/

		EXEC [Email].[Newsletter_OfferPrioritisation_EmailSend] @EmailDate

End