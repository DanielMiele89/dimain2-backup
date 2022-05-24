
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

--	Declare @EmailDate Date = '2021-08-26'

	/*******************************************************************************************************************************************
		1. Prepare tables for validation
	*******************************************************************************************************************************************/

		DECLARE @ClubID INT = 180

		If Object_ID('tempdb..#IronOffer') Is Not Null Drop Table #IronOffer
		SELECT *
		INTO #IronOffer
		FROM [Derived].[IronOffer]
		WHERE ClubID = @ClubID
		
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
			Where IronOfferID Is Null
			And PartnerName Is Null
													 

		/***********************************************************************************************************************
			1.3. Generate weighting for all offers
		***********************************************************************************************************************/

			IF Object_ID('tempdb..#OfferDetailsFromOPE') Is Not Null Drop Table #OfferDetailsFromOPE
			Select IronOfferID as OfferID
				 , 1001 - ROW_NUMBER() over (order by (select null)) as Weighting
				 , Case
						When IronOfferName like 'Core %' or BaseOffer like 'Core %' then 1
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
				 , ClientServicesRef
				 , iof.Item AS IronOfferID
			INTO #CampaignSetup
			FROM (SELECT ClientServicesRef
				  	   , OfferID
				  FROM [Selections].[CampaignSetup_POS]
				  WHERE @EmailDate BETWEEN StartDate And EndDate) cs
				  CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
			WHERE iof.Item != 0


	/*******************************************************************************************************************************************
		3. For each possible error, add them to the previously created holding table with a flag of what those errors are
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Offers duplicated in the OPE
		***********************************************************************************************************************/

			IF Object_ID('tempdb..#OffersDuplicatedInOPE') Is Not Null Drop Table #OffersDuplicatedInOPE
			Select ope.OfferID as IronOfferID
				 , Min(Weighting) as MinWeighting
			Into #OffersDuplicatedInOPE
			From #OfferDetailsFromOPE ope
			Group by ope.OfferID
			Having Count(1) > 1

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, Duplicated)
			Select i.IronOfferID
				 , i.IronOfferName
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
				on op.IronOfferID=i.IronOfferID
			

		/***********************************************************************************************************************
			3.2. Offers going live that are not in the OPE
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, OfferMissingFromOPE)
			Select Distinct 
				   i.IronOfferID
				 , i.IronOfferName
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
			and i.IronOfferName Not in ('suppressed','SPARE','SPARE!!!')
			and not exists (Select 1
							From #OfferDetailsFromOPE op
							Where i.IronOfferID = op.OfferID)
			------ Constant Exclusions
			and i.PartnerID not in (Select PartnerID from Warehouse.APW.PartnerAlternate)	-- Secondary Partner Recorda
			


		/***********************************************************************************************************************
			3.3. Offers in the OPE that are not in IronOffer
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, OfferInOPENotInIronOffer)
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
							  Where op.OfferID = iof.IronOfferID)
			

		/***********************************************************************************************************************
			3.4. Offers ending before the cycle end date
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, EndBeforeCycleEnds)
			Select iof.IronOfferID
				 , iof.IronOfferName
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
				on op.OfferID = iof.IronOfferID
			Where iof.EndDate < DateAdd(millisecond, -1003, DateAdd(day, 14, Convert(DateTime, @EmailDate)))
			

		/***********************************************************************************************************************
			3.5. Offers starting after the cycle start date
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, StartAfterCycleStart)
			Select iof.IronOfferID
				 , iof.IronOfferName
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
				on op.OfferID = iof.IronOfferID
			Where iof.StartDate > @EmailDate
			

		/***********************************************************************************************************************
			3.6. Offers that are in the OPE but are not in the CampaignSetup_POS table 
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, OfferInOPEMissingFromSelections)
			Select op.OfferID as IronOfferID
				 , iof.IronOfferName
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
				on op.OfferID = iof.IronOfferID
			Where Not Exists (Select 1
							  From #CampaignSetup cs
							  Where op.OfferID = cs.IronOfferID
							  Or op.Base = 1
							  Or op.OfferID = 14011)
			

		/***********************************************************************************************************************
			3.7. Offers that are in the CampaignSetup_POS table but are not in the OPE
		***********************************************************************************************************************/

			Insert Into #Newsletter_OfferPrioritisation_Errors (IronOfferID
														, IronOfferName
														, StartDate
														, EndDate
														, PartnerID
														, NewOffer
														, OfferInSelectionsMissingFromOPE)
			Select als.IronOfferID
				 , iof.IronOfferName
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
				on als.IronOfferID = iof.IronOfferID
			Where Not Exists (Select 1
							  From #OfferDetailsFromOPE op
							  Where op.OfferID = als.IronOfferID)


	/*******************************************************************************************************************************************
		4. Combine all offers with errors are create single status column listing all errors per offer
	*******************************************************************************************************************************************/
	
		If Object_ID('tempdb..##Newsletter_OfferPrioritisation_Errors') Is Not Null Drop Table ##Newsletter_OfferPrioritisation_Errors
		Select IronOfferID
			 , IronOfferName
			 , StartDate
			 , EndDate
			 , PartnerID
			 , NewOffer
			 , Replace(Left(Status, Len(Status) - 1), ', Offer', ',') as Status
		INTO ##Newsletter_OfferPrioritisation_Errors
		From (Select IronOfferID
	  			   , IronOfferName
	  			   , StartDate
	  			   , EndDate
	  			   , PartnerID
	  			   , NewOffer
	  			   , Case When Max(Duplicated) = 1 Then 'Offer duplicated in OPE, ' Else '' End
	  				 +
	  				 Case When Max(EndBeforeCycleEnds) = 1 Then 'Offer ends before cycle ends, ' Else '' End
	  				 +
	  				 Case When Max(StartAfterCycleStart) = 1 Then 'Offer starts after cycle starts, ' Else '' End
	  				 +
	  				 Case When Max(OfferMissingFromOPE) = 1 Then 'Offer not listed in the OPE, ' Else '' End
	  				 +
	  				 Case When Max(OfferInOPENotInIronOffer) = 1 Then 'Offer in the OPE but not found in IronOffer table, ' Else '' End
	  				 +
	  				 Case When Max(OfferInOPEMissingFromSelections) = 1 Then 'Offer in the OPE but not set up for selection, ' Else '' End
	  				 +
	  				 Case When Max(OfferInSelectionsMissingFromOPE) = 1 Then 'Offer set up for selection but not in the OPE, ' Else '' End as Status
			  From #Newsletter_OfferPrioritisation_Errors
			  Group by IronOfferID
	  			   , IronOfferName
	  			   , StartDate
	  			   , EndDate
	  			   , PartnerID
	  			   , NewOffer) owe

		UPDATE ##Newsletter_OfferPrioritisation_Errors
		SET Status = 'Offer not listed in the OPE'
		WHERE Status = 'Offer not listed in the OPE, set up for selection but not in the OPE'
				   

	/*******************************************************************************************************************************************
		5. For permanent exclusions give the reason
	*******************************************************************************************************************************************/

		UPDATE owe
		SET owe.Status = owe.Status + ' - ' + pe.ExclusionReason
		FROM ##Newsletter_OfferPrioritisation_Errors owe
		INNER JOIN [Email].[OPE_PartnerExclusions] pe
			ON owe.PartnerID = pe.PartnerID
			AND @EmailDate BETWEEN pe.StartDate AND COALESCE(pe.EndDate, '9999-12-31')
		

	/*******************************************************************************************************************************************
		6. Insert all entries of OPE to a reviewd table, listing errors where applicable
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
		7. Insert all entries of OPE to a reviewd table, listing errors where applicable
	*******************************************************************************************************************************************/

		Delete
		From [Email].[Newsletter_OfferPrioritisation]
		Where EmailDate = @EmailDate

		INSERT INTO [Email].[Newsletter_OfferPrioritisation]
		Select iof.PartnerID
			 , op.OfferID
			 , op.Weighting
			 , op.Base
			 , Case
					When StartDate >= GetDate() Or StartDate Is Null Then 1
					Else 0
			   End as NewOffer
			 , @EmailDate as EmailDate
		From #OfferDetailsFromOPE op
		Left join [Derived].[IronOffer] iof
			on op.OfferID = iof.IronOfferID

	/*******************************************************************************************************************************************
		8. Insert all entries of OPE to a reviewd table, listing errors where applicable
	*******************************************************************************************************************************************/

		EXEC [Email].[Newsletter_OfferPrioritisation_EmailSend] @EmailDate

End