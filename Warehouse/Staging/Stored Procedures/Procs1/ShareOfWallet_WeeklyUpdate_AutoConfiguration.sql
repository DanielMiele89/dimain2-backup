/*
		Author:		Stuart Barnley

		Date:		9th December 2015


		Purose:		To restrict the weekly SoW run on Sundays to just 
					those needed to fulfil the offers starting between
					2 dates

		Updates:	N/A


*/
CREATE Procedure Staging.ShareOfWallet_WeeklyUpdate_AutoConfiguration
				@StartDate Date,
				@EndDate Date,
				@Update bit
As

Declare @qry nvarchar(Max)

---------------------------------------------------------------------
-------------Find which SoW needs runnings based on dates------------
---------------------------------------------------------------------
--Create a table that gives a unique list of partners to be Share of 
--Wallet'ed


Select Distinct Cast(PartnerID as varchar(4)) as PartnerString
into #PartnerStrings
From SLC_Report..IronOffer as i
inner join SLC_Report..IronOfferClub as ioc
	on i.ID = ioc.IronOfferID
Where 	ClubID in (132,138) and
	i.Startdate Between @StartDate and @EndDate

If @Update = 1
Begin

--  Update the table by setting all records to No and then the needed 
--	records to Yes

	Set @Qry = '
	--------------------------------------------------------------------
	----------------------------Update all to off-----------------------
	--------------------------------------------------------------------
	Select * From #PartnerStrings
	--------------------------------------------------------------------
	----------------------------Update all to off-----------------------
	--------------------------------------------------------------------
	Update Warehouse.Relational.PartnerStrings
	Set HTM_Current = 0

	Update Warehouse.Relational.PartnerStrings
	Set HTM_Current = 1 
	From Warehouse.Relational.PartnerStrings as a
	inner join #PartnerStrings as ps
		on a.PartnerString =ps.PartnerString
	'
End

If @Update = 0
Begin

--	Display a list of those records that would be updated if the process
--	was run with @Update = 1
	Set @Qry = '
	--------------------------------------------------------------------
	----------------------------Update all to off-----------------------
	--------------------------------------------------------------------
	Select * From #PartnerStrings
'
End
Exec sp_ExecuteSQL @Qry