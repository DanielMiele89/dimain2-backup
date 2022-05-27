
CREATE PROCEDURE [Staging].[SSRS_R0184_MIDCheck_v2]


AS
BEGIN

	if object_id('tempdb..#DriveTime') is not null drop table #DriveTime
	Create Table #DriveTime (LoopNumber INT
							,PartnerID INT
							,FromOutletID INT
							,ToOutletID INT
							,FromPostSector varchar(10)
							,ToPostSector varchar(10))


	Declare @PartnerID INT = (Select MIN(PartnerID) From Sandbox.Rory.SSRS_R0184_MIDCheck),
			@MaxPartnerID INT = (Select MAX(PartnerID) From Sandbox.Rory.SSRS_R0184_MIDCheck),
			@RowNumber INT,
			@MaxRowNumber INT,
			@LoopNumber INT = 1

	While @PartnerID <= @MaxPartnerID
		Begin 
			if object_id('tempdb..#DriveTimePartnerLoop') is not null drop table #DriveTimePartnerLoop
			Select fc.PartnerID
				 , fc.OutletID
				 , fc.MerchantID
				 , fc.PostSector
				 , ROW_NUMBER() Over (Order by SuppressFromSearch desc, MaxTranDate Desc, Address1 Desc, Address2 Desc) as RowNumber
			Into #DriveTimePartnerLoop
			From Sandbox.Rory.SSRS_R0184_MIDCheck fc
			Where fc.PostSector is not null
			And StatusOfMID = 'Live MID'
			And fc.PartnerID = @PartnerID
			
			Set @RowNumber = (Select MIN(RowNumber) From #DriveTimePartnerLoop)
			Set @MaxRowNumber = (Select MAX(RowNumber) From #DriveTimePartnerLoop)

			While @RowNumber <= @MaxRowNumber
				Begin 
					if object_id('tempdb..#DriveTimeOutletLoop') is not null drop table #DriveTimeOutletLoop
					Select OutletID
						 , PostSector
					Into #DriveTimeOutletLoop
					From #DriveTimePartnerLoop
					Where RowNumber = @RowNumber

					Delete
					From #DriveTimePartnerLoop
					Where RowNumber = @RowNumber

					if object_id('tempdb..#DriveTimeNearbyOutlets') is not null drop table #DriveTimeNearbyOutlets
					Select @LoopNumber as LoopNumber
						 , @PartnerID as PartnerID
						 , ol.OutletID as FromOutletID
						 , pl.OutletID as ToOutletID
						 , ol.PostSector as FromPostSector
						 , pl.PostSector as ToPostSector
					Into #DriveTimeNearbyOutlets
					From #DriveTimeOutletLoop ol
					Cross join #DriveTimePartnerLoop pl
					Inner join Warehouse.Relational.DriveTimeMatrix dtm
						on	ol.PostSector=dtm.FromSector
						and	pl.PostSector=dtm.ToSector
					Where DriveDistMiles < 0.5
					And ol.OutletID <> pl.OutletID

					Insert into #DriveTime
					Select *
					From #DriveTimeNearbyOutlets

					Set @LoopNumber = @LoopNumber + 1
					Set @RowNumber = (Select MIN(RowNumber) From #DriveTimePartnerLoop Where RowNumber > @RowNumber)

				End		--	While @OutletID <= @MaxOutletID
			
			Set @PartnerID = (Select MIN(PartnerID) From Sandbox.Rory.SSRS_R0184_MIDCheck Where PartnerID > @PartnerID)		

		End -- While @PartnerID <= @MaxPartnerID

	Select dt.LoopNumber			as LoopNumber
		 , dt.PartnerID				as PartnerID
		 , mcf.PartnerName			as PartnerName
		 , dt.FromOutletID			as FromOutletID
		 , mcf.MerchantID			as MerchantID_From
		 , mcf.SuppressFromSearch	as SuppressFromSearch_From
		 , mcf.Address1				as Address1_From
		 , mcf.Address2				as Address2_From
		 , mcf.City					as City_From
		 , mcf.Postcode				as Postcode_From
		 , mcf.PostSector			as PostSector_From
		 , mcf.MinTranDate			as MinTranDate_From
		 , mcf.MaxTranDate			as MaxTranDate_From
		 , dt.ToOutletID			as ToOutletID_To
		 , mct.MerchantID			as MerchantID_To
		 , mct.SuppressFromSearch	as SuppressFromSearch_To
		 , mct.Address1				as Address1_To
		 , mct.Address2				as Address2_To
		 , mct.City					as City_To
		 , mct.Postcode				as Postcode_To
		 , mct.PostSector			as PostSector_To
		 , mct.MinTranDate			as MinTranDate_To
		 , mct.MaxTranDate			as MaxTranDate_To
	From #DriveTime dt
	Inner join Sandbox.Rory.SSRS_R0184_MIDCheck mcf
		on dt.FromOutletID = mcf.OutletID
	Inner join Sandbox.Rory.SSRS_R0184_MIDCheck mct
		on dt.ToOutletID = mct.OutletID
	Order by LoopNumber

End