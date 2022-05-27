
CREATE PROCEDURE [Staging].[SSRS_R0184_MIDCheck]


AS
BEGIN

--------------------------------------------------------------------------------
------------------------ Fetch all RBS or unknown MIDs  ------------------------
--------------------------------------------------------------------------------

	if object_id('tempdb..#MIDMatch') is not null drop table #MIDMatch
	Select Distinct
			  RetailOutletID
			, MerchantID
	Into #MIDMatch
	From SLC_Report..Match
	Where VectorID in (37,38)
	Or VectorID is null

--------------------------------------------------------------------------------
---------------- Put all MIDs into temp table with relevant data ---------------
-------------------------------------------------------------------------------- 
	
	if object_id('tempdb..#MIDList') is not null drop table #MIDList
	Select ro.ID as OutletID
		 , ro.MerchantID
		 , ro.Channel
		 , Case
			 	When ro.Channel=0 then'Unknown'
			 	When ro.Channel=1 then'Online'
			 	When ro.Channel=2 then'Offline'
		   End as ChannelType
		 , LOWER(LTRIM(RTRIM(replace(replace(replace(f.Address1,' ','<>'),'><',''),'<>',' ' )))) as Address1
		 , LOWER(LTRIM(RTRIM(replace(replace(replace(f.Address2,' ','<>'),'><',''),'<>',' ' )))) as Address2
		 , LOWER(LTRIM(RTRIM(replace(replace(replace(f.City,' ','<>'),'><',''),'<>',' ' )))) as City
		 , LOWER(LTRIM(RTRIM(replace(replace(replace(f.Postcode,' ','<>'),'><',''),'<>','' )))) as Postcode
		 , Coalesce(Cast(Coordinates as varchar(150)),'') as Coordinates
		 , ro.SuppressFromSearch
		 , Case
		  		When LEN(ro.MerchantID) > 0 and ro.MerchantID not like '%archive%' and PATINDEX('%[0-9]%', ro.MerchantID) <> 1 and LEFT(ro.MerchantID,1) not in ('#','x') and mma.MerchantID is null Then 'Unknown'
		  		When LEN(ro.MerchantID)=0 Then 'Hashed Out Mid'
		  		When PATINDEX('%[1-9]%',ro.MerchantID)=0 Then 'Hashed Out Mid'
		  		When PATINDEX('%[0-9]%', ro.MerchantID) <> 1 and ro.MerchantID <> mma.MerchantID Then 'Hashed Out Mid'
		  		When PATINDEX('%[0-9]%', ro.MerchantID) <> 1 and mma.MerchantID is null Then 'Hashed Out Mid'
		  		Else 'Live MID'
		   End as StatusOfMID
		 , ro.PartnerID
	Into #MIDList
	From slc_report.dbo.RetailOutlet as ro
	Inner join slc_report..Fan as f
		on ro.fanid = f.id
	Inner join #MIDMatch mma
		on ro.ID=mma.RetailOutletID


	if object_id('tempdb..#PartnerList') is not null drop table #PartnerList
	Select pa.ID as PartnerID
		 , pa.Name as PartnerName
		 , Coalesce(iof.DoesPartnerHaveLiveOffers,'No') as LiveOffers
	Into #PartnerList
	From SLC_Report..Partner pa
	Left join (	Select Distinct PartnerID
							, 'Yes' as DoesPartnerHaveLiveOffers
			From Warehouse.Relational.IronOffer
			Where StartDate is not null
			And (EndDate>GETDATE() or EndDate is null)
			And IsSignedOff=1
			And IsDefaultCollateral=0
			And IsAboveTheLine=0) iof
		on pa.id=iof.PartnerID
	Inner join (Select Distinct PartnerID
				From Warehouse.Relational.IronOffer
				Where StartDate is not null
				And (EndDate is null or EndDate>(DATEADD(Year,-1,GETDATE())))
				And IsSignedOff=1
				And IsDefaultCollateral=0
				And IsAboveTheLine=0) iof2
		on pa.id=iof2.PartnerID

	if object_id('tempdb..#CheckMIDs') is not null drop table #CheckMIDs
	Select ml.OutletID
		 , ml.MerchantID
		 , ml.Channel
		 , ml.ChannelType
		 , ml.Address1
		 , ml.Address2
		 , ml.City
		 , ml.Postcode
		 , pc.PostSector
		 , ml.Coordinates
		 , ml.SuppressFromSearch
		 , pl.PartnerID
		 , pl.PartnerName
		 , pl.LiveOffers
		 , ml.StatusOfMID
	Into #CheckMIDs
	From #MIDList ml
	Inner join #PartnerList pl
		on ml.PartnerID = pl.PartnerID
	Left join Relational.PostCode pc
		on ml.Postcode = LOWER(LTRIM(RTRIM(replace(replace(replace(pc.Postcode,' ','<>'),'><',''),'<>','' ))))
 
--------------------------------------------------------------------------------
------------------- Get counts of MIDs by Partner & Postcode -------------------
--------------------------------------------------------------------------------
	if object_id('tempdb..#MIDCounts') is not null drop table #MIDCounts
	Select PartnerID
		 , Postcode
		 , Count(MerchantID) as MIDs
		 , Sum(Cast(SuppressFromSearch as INT)) as SuppresedMIDs
		 , Sum( Case
					When StatusOfMID = 'Live MID' then Cast(SuppressFromSearch as INT)
					Else 0
				End) as SuppresedLiveMIDs
	Into #MIDCounts
	From #CheckMIDs
	Group by PartnerID
			,Postcode
 
--------------------------------------------------------------------------------
-------- Classify postcodes by the difference in MIDs to suprresed MIDs --------
--------------------------------------------------------------------------------
	if object_id('tempdb..#MIDsCheck2') is not null drop table #MIDsCheck2
	Select cm.LiveOffers
		 , cm.PartnerName
		 , cm.PartnerID
		 , cm.OutletID
		 , cm.Address1
		 , cm.Address2
		 , cm.City
		 , cm.Postcode
		 , cm.PostSector
		 , cm.Coordinates
		 , mc.MIDs
		 , mc.SuppresedMIDs
		 , mc.SuppresedLiveMIDs
		 , Case
		 		When (MIDs-SuppresedLiveMIDs)=1 Then '1. One MID unsuppressed for this postcode - good'
		 		When LEN(cm.Postcode)=0 And cm.ChannelType <> '1' And (MIDs=SuppresedLiveMIDs) And SuppresedLiveMIDs>0 Then '2. All MIDs suppressed for and no postcode - good'
		 		When cm.ChannelType = '1' And (MIDs=SuppresedLiveMIDs) And SuppresedLiveMIDs>0 Then '3. All MIDs suppressed and Online - good'
		 		When csm.OutletID is not null Then '4. All MIDs suppressed for this postcode, confirmed - good'
		 		When LEN(cm.Postcode) > 0 And cm.ChannelType <> '1' And (MIDs=SuppresedLiveMIDs) And SuppresedLiveMIDs>0 Then '5. All MIDs suppressed for this postcode - unsure'
		 		When (SuppresedLiveMIDs)=0 Then '6. No MIDs supressed for this postcode - bad'
		 		When (MIDs-SuppresedLiveMIDs)<>1 Then '7. Multiple MIDs unsupressed for this postcode - bad'
		 		Else 'Review case statement'
		   End as StatusOfPostcodeLiveMIDs
		 , cm.MerchantID
		 , cm.StatusOfMID
		 , cm.Channel
		 , cm.ChannelType
		 , cm.SuppressFromSearch
	Into #MIDsCheck2
	From #CheckMIDs cm
	Inner join #MIDCounts mc
		on  cm.PartnerID=mc.PartnerID
		and cm.Postcode=mc.Postcode
	Left join Warehouse.Staging.SSRS_R0184_MIDCheck_CorrectlySuppressedMIDs csm
		on cm.OutletID = csm.OutletID
	Order by cm.LiveOffers desc
			,cm.PartnerName
			,cm.Coordinates
			,mc.Postcode
			,Address1 Desc
			,Address2 Desc
			,cm.OutletID

--------------------------------------------------------------------------------
------------------ Select MIDs of Outlets with Multiple MIDs -------------------
--------------------------------------------------------------------------------
 

	if object_id('tempdb..#PostcodesWithMultipleMIDs') is not null drop table #PostcodesWithMultipleMIDs
	Select Distinct MerchantID
	Into #PostcodesWithMultipleMIDs
	From #MIDsCheck2
	Where	MIDs>1
	
 
--------------------------------------------------------------------------------
-------- Select Max Transactions of MIDs of Outlets with Multiple MIDs ---------
--------------------------------------------------------------------------------
	
	--MID list
	if object_id('tempdb..#TranMIDList') is not null drop table #TranMIDList
	Select Distinct
			  OutletID
	Into #TranMIDList
	From #MIDsCheck2
	
	-- Max Trans
	if object_id('tempdb..#MaxTranOutlet') is not null drop table #MaxTranOutlet
	Select ma.RetailOutletID
		 , Min(ma.TransactionDate) as MinTranDate
		 , Max(ma.TransactionDate) as MaxTranDate
	Into #MaxTranOutlet
	From SLC_Report..Match ma  WITH (NOLOCK)
	Inner join #TranMIDList mtml
		on mtml.OutletID=ma.RetailOutletID
	Group by ma.RetailOutletID

--------------------------------------------------------------------------------
---------------------------- Merge with full dataset ---------------------------
--------------------------------------------------------------------------------	 

	if OBJECT_ID('Sandbox.Rory.SSRS_R0184_MIDCheck') is not null drop table Sandbox.Rory.SSRS_R0184_MIDCheck
	Select mct.LiveOffers
		 , mct.PartnerName
		 , mct.PartnerID
		 , mct.OutletID
		 , mct.Address1
		 , mct.Address2
		 , mct.City
		 , mct.Postcode
		 , mct.PostSector
		 , mct.Coordinates
		 , mct.MIDs
		 , mct.SuppresedMIDs
		 , mct.SuppresedLiveMIDs
		 , mct.StatusOfPostcodeLiveMIDs
		 , mct.MerchantID
		 , mct.StatusOfMID
		 , mct.Channel
		 , mct.ChannelType
		 , mct.SuppressFromSearch
		 , mto.MaxTranDate
		 , mto.MinTranDate
	Into Sandbox.Rory.SSRS_R0184_MIDCheck
	From #MIDsCheck2 mct
	Left Join #MaxTranOutlet mto
		on mct.OutletID=mto.RetailOutletID
	Order by LiveOffers desc
			,PartnerName
			,Postcode
			,Address1 Desc
			,Address2 Desc
			,OutletID

--------------------------------------------------------------------------------
------------------- Fetch cases where there are multiple MIDs ------------------
--------------------------------------------------------------------------------

	if object_id('tempdb..#WhichToSuppress') is not null drop table #WhichToSuppress
	Select PartnerID
		 , PartnerName
		 , OutletID
		 , MerchantID
		 , Address1
		 , Address2
		 , City
		 , Postcode
		 , Coordinates
		 , ChannelType
		 , MaxTranDate
		 , MinTranDate
		 , ROW_NUMBER() Over (Partition by PartnerID, Postcode Order by Case when Coordinates in ('','POINT (0 0)') then '' else 'n' end desc, MaxTranDate Desc, Address1 Desc, Address2 Desc) as Postcode_Rank
	Into #WhichToSuppress
	From Sandbox.Rory.SSRS_R0184_MIDCheck
	Where StatusOfPostcodeLiveMIDs like '%- bad%'
	and SuppressFromSearch=0
	and LEN(Postcode)>0
	and StatusOfMID = 'Live MID'
	Order by LiveOffers desc
			,PartnerName
			,Postcode
			,ROW_NUMBER() Over (Partition by PartnerID, Postcode Order by MaxTranDate Desc, Address1 Desc, Address2 Desc)
			,Address1 Desc
			,Address2 Desc

--------------------------------------------------------------------------------
----------------- Run query to determine which MID to suppress -----------------
--------------------------------------------------------------------------------			

	if object_id('tempdb..#WhichToSuppress2') is not null drop table #WhichToSuppress2
	Select fc1.PartnerID
		 , fc1.PartnerName
		 , fc1.Address1
		 , fc1.Address2
		 , fc1.City
		 , fc1.Postcode
		 , fc1.Coordinates_1
		 , fc2.Coordinates_2
		 , fc1.OutletID_1
		 , fc1.MerchantID_1
		 , fc1.MaxTranDate_1
		 , fc1.MinTranDate_1
		 , fc2.OutletID_2
		 , fc2.MerchantID_2
		 , fc2.MaxTranDate_2
		 , fc2.MinTranDate_2
		 , ToBeSuppressed_1
		 , ToBeSuppressed_2
	Into #WhichToSuppress2
	From (	Select PartnerID
				 , PartnerName
				 , OutletID as OutletID_1
				 , MerchantID as MerchantID_1
				 , Address1
				 , Address2
				 , City
				 , Postcode
				 , Coordinates as Coordinates_1
				 , MaxTranDate as MaxTranDate_1
				 , MinTranDate as MinTranDate_1
				 , 'No' as ToBeSuppressed_1
			From #WhichToSuppress
			Where Postcode_Rank=1) fc1
	Inner join (	Select PartnerID
					 , PartnerName
					 , OutletID as OutletID_2
					 , MerchantID as MerchantID_2
					 , Address1
					 , Address2
					 , City
					 , Postcode
					 , Coordinates as Coordinates_2
					 , MaxTranDate as MaxTranDate_2
					 , MinTranDate as MinTranDate_2
					 , 'Multiple MIDs on this postcode' as ToBeSuppressed_2
			From #WhichToSuppress
			Where Postcode_Rank>1) fc2
		on	fc1.PartnerID=fc2.PartnerID
		and fc1.Postcode=fc2.Postcode
		and fc1.MerchantID_1<>fc2.MerchantID_2
	Order by fc1.PartnerName
			,fc1.Postcode
			,fc1.Address1 Desc
			,fc1.Address2 Desc

--------------------------------------------------------------------------------
---------------- Update table holding correctly suppressed MIDs ----------------
--------------------------------------------------------------------------------

	Update csp
	Set	   csp.PartnerName	= fc.PartnerName
		 , csp.PartnerID	= fc.PartnerID
		 , csp.OutletID		= fc.OutletID
		 , csp.Address1		= fc.Address1
		 , csp.Address2		= fc.Address2
		 , csp.City			= fc.City
		 , csp.Postcode		= fc.Postcode
		 , csp.MerchantID	= fc.MerchantID
		 , csp.ChannelType	= fc.ChannelType
	From Warehouse.Staging.SSRS_R0184_MIDCheck_CorrectlySuppressedMIDs csp
	Inner join Sandbox.Rory.SSRS_R0184_MIDCheck fc
		on csp.OutletID = fc.OutletID

--------------------------------------------------------------------------------
--------------------------------- Final dataset --------------------------------
--------------------------------------------------------------------------------

	Select Distinct 
		   fc.LiveOffers
		 , fc.PartnerName
		 , fc.PartnerID
		 , fc.OutletID
		 , fc.Address1
		 , fc.Address2
		 , fc.City
		 , fc.Postcode
		 , Convert(varchar(12),fc.PartnerID) + ' ' + fc.Postcode as PartnerPostcode
		 , fc.Coordinates
		 , fc.MIDs
		 , fc.SuppresedMIDs
		 , fc.SuppresedLiveMIDs
		 , fc.StatusOfPostcodeLiveMIDs
		 , fc.MerchantID
		 , fc.StatusOfMID
		 , fc.Channel
		 , fc.ChannelType
		 , fc.SuppressFromSearch
		 , fc.MaxTranDate
		 , fc.MinTranDate
		 , Case
				When fc.StatusOfMID = 'Hashed Out Mid' and fc.SuppressFromSearch = 0 then fc.StatusOfMID
				When fc.ChannelType = 'Online' and fc.SuppressFromSearch = 0 then 'Online MID'
				When wts.ToBeSuppressed_2 is not null then wts.ToBeSuppressed_2
				When LEN(fc.Coordinates)<12 And LEN(fc.Postcode) = '' And fc.Address1 = '' and fc.SuppressFromSearch = 0 then 'Not enough address information'
		   End as ToBeSuppressed
		 , Case when wts2.ToBeSuppressed_2 = 'Multiple MIDs on this postcode' and fc.StatusOfMID <> 'Hashed Out Mid' and fc.ChannelType <> 'Online' then wts2.OutletID_1 else null end as OutletID_ToRemainUnsuppressed
		 , Case when wts2.ToBeSuppressed_2 = 'Multiple MIDs on this postcode' and fc.StatusOfMID <> 'Hashed Out Mid' and fc.ChannelType <> 'Online' then wts2.MerchantID_1 else null end as MerchantID_ToRemainUnsuppressed
		 , Case when wts2.ToBeSuppressed_2 = 'Multiple MIDs on this postcode' and fc.StatusOfMID <> 'Hashed Out Mid' and fc.ChannelType <> 'Online' then wts2.MaxTranDate_1 else null end as MaxTranDate_ToRemainUnsuppressed
		 , Case when wts2.ToBeSuppressed_2 = 'Multiple MIDs on this postcode' and fc.StatusOfMID <> 'Hashed Out Mid' and fc.ChannelType <> 'Online' then wts2.MinTranDate_1 else null end as MinTranDate_ToRemainUnsuppressed
	From Sandbox.Rory.SSRS_R0184_MIDCheck fc
	Left Join #WhichToSuppress2 wts
		on fc.OutletID=wts.OutletID_2
	Left Join #WhichToSuppress2 wts2
		on fc.OutletID=wts2.OutletID_2
		and wts2.ToBeSuppressed_2 = 'Multiple MIDs on this postcode'
		and fc.StatusOfMID <> 'Hashed Out Mid'
		and fc.ChannelType <> 'Online'
	Order by fc.LiveOffers desc
			,fc.PartnerName
			,fc.Postcode
			,fc.Address1 Desc
			,fc.Address2 Desc
			,fc.OutletID

End