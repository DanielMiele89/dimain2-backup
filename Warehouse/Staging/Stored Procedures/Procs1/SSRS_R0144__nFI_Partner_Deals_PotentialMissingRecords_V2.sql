

CREATE procedure [Staging].[SSRS_R0144__nFI_Partner_Deals_PotentialMissingRecords_V2]

As 
Begin

/********************************************************************************************
Name: Staging.SSRS_R0144__nFI_Partner_Deals_PotentialMissingRecords_V2
Desc: Used to create a results set for R_0144 to detect potential missing rows in the 
		 Relational.nFI_Partner_Deals table
Auth: Zoe Taylor
Date: 2017-01-06
*********************************************************************************************
Change History
---------------------
No	Date		Author			Description 
--	-----		-------			------------------------------------
1    10/05/2017	Zoe Taylor		V2 created 
								* to populate rows when an offer is due to go live, rather 
								than when members are added

*********************************************************************************************/

/******************************************************************		
		Get all partner/publisher combinations that have live offers 
		in the database that aren't in the partnerdeals table
******************************************************************/

	If Object_ID('tempdb..#Combinations') is not null Drop Table #Combinations
	Select Distinct io.ClubID
		, io.PartnerID
	Into #Combinations
	from nFI.Relational.IronOffer io
	Left join Warehouse.Relational.nFI_Partner_Deals pd
		on pd.PartnerID = io.PartnerID
		and pd.ClubID = io.ClubID
	Where io.IsSignedOff = 1
		and (pd.PartnerID is null and pd.ClubID is null)
Union All	
	Select Distinct 132 [ClubID]
		, io.PartnerID
	from Warehouse.Relational.IronOffer io
	Left join Warehouse.Relational.nFI_Partner_Deals pd
		on pd.PartnerID = io.PartnerID
		and pd.ClubID = 132
	Where io.IsSignedOff = 1
		and (pd.PartnerID is null and pd.ClubID is null)

		select * from #combinations

/******************************************************************		
		Where offer has ended, only show where we have incentivesed
		transactions 
******************************************************************/




/******************************************************************		
		Display rows 
******************************************************************/

	Select x.ClubID
		, c.Name [ClubName]
		, x.PartnerID
		, p.Name [PartnerName]
	From #Combinations x
	Inner Join SLC_Report..Club c
		on x.clubid = c.id
	Inner join SLC_Report..Partner p
		on x.PartnerID = p.ID
	Left Join Prototype.nFIPartnerDeals_RBSExclusions ex
		on ex.partnerid = x.partnerid
	Left Join Warehouse.APW.PartnerAlternate pa
		on pa.PartnerID = x.partnerid
	Where ex.PartnerID is NULL
		and pa.AlternatePartnerID is null

End


