/******************************************************************************
Author: Jason Shipp
Created: 15/03/2018
Purpose:
	- Load new entries into nFI.Relational.IronOffer_References table
	- Load validation of offer types assigned to the new entries
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_nFINonAAM_Load_IronOffer_References]

AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load offer cycles
	******************************************************************************/

	If  object_id ('tempdb..#OCs') is not null drop table #OCs;

	Select distinct
		OfferCyclesID
	Into #OCs
	From Warehouse.Staging.ControlSetup_Cycle_Dates d
	Left join (Select StartDate, EndDate, OfferCyclesID from nFI.Relational.OfferCycles Union all Select StartDate, EndDate, OfferCyclesID from Warehouse.Relational.OfferCycles) oc
		on	(d.StartDate <= oc.EndDate or oc.EndDate is null)
		and d.EndDate > oc.Startdate;

	/******************************************************************************
	Load cashback rules
	******************************************************************************/

	If  object_id ('tempdb..#CashbackRate_nFI') is not null drop table #CashbackRate_nFI;
	
	Select
		IronOfferID
		, Max(Case
			When MinimumBasketSize is null then CommissionRate
			Else 0
		End) as CashbackRate
		, Max(MinimumBasketSize) as BasketSize
		, Max(Case
			When MinimumBasketSize > 0 then CommissionRate
			Else NULL
		End) as SpendStretchCashbackRate
	Into #CashbackRate_nFI
	From nFI.Relational.IronOffer_PartnerCommissionRule pcr
	Where
		Status = 1
		and typeid = 1
	Group by
		IronOfferID;

	/******************************************************************************
	Generate entries to be added to nFI.Relational.IronOffer_References table
	******************************************************************************/

	If object_id ('tempdb..#IronOffer_Ref_nFI') is not null drop table #IronOffer_Ref_nFI;

	Select
		i.ID as IronOfferID
		, i.ClubID as ClubID
		, ioc.IronOfferCyclesID
		, s.SegmentID AS ShopperSegmentID
		, s.OfferTypeID
		, cb.CashbackRate as CashbackRate
		, cb.BasketSize as SpendStretch
		, cb.SpendStretchCashbackRate as SpendStretchRate
	Into #IronOffer_Ref_nFI
	From nFI.Relational.Ironoffercycles ioc
	Inner join nFI.Relational.IronOffer i
		on ioc.ironofferid = i.id
	Inner join #CashbackRate_nFI cb
		on i.ID = cb.IronOfferID
	Inner join #OCs o
		on o.offercyclesid = ioc.offercyclesid
	Left join Warehouse.Relational.IronOfferSegment s
		on i.ID = s.IronOfferID;

	/******************************************************************************
	Load new entries into nFI.Relational.IronOffer_References table
	******************************************************************************/

	Insert into nFI.Relational.IronOffer_References
	Select
		i.*
	From #IronOffer_Ref_nFI i
	Left join nFI.Relational.IronOffer_References a
		on i.ironoffercyclesid = a.ironoffercyclesid
	Where
		a.ironoffercyclesid is null;

	/******************************************************************************
	CHECK POINT: Validate entries added to nFI.Relational.IronOffer_References table

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_IronOffer_References
		(PublisherType VARCHAR(50)
		, IronOfferID INT
		, StartDate DATE
		, EndDate DATE
		, ClubID INT
		, ironoffercyclesid INT
		, ShopperSegmentID INT
		, SegmentName VARCHAR(50)
		, OfferTypeID INT
		, TypeDescription VARCHAR(50)
		, CashbackRate FLOAT
		, SpendStretch FLOAT
		, SpendStretchRate FLOAT
		, offercyclesid INT
		, controlgroupid INT
		, IronOfferName NVARCHAR(200)
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_IronOffer_References PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	If object_id ('tempdb..#IORCheckData') is not null drop table #IORCheckData;
	
	Select
		'nFI' as PublisherType
		, i.IronOfferID
		, oc.StartDate
		, oc.EndDate
		, i.ClubID
		, i.ironoffercyclesid
		, i.ShopperSegmentID
		, st.SegmentName
		, i.OfferTypeID
		, ot.TypeDescription
		, i.CashbackRate
		, i.SpendStretch
		, i.SpendStretchRate
		, ioc.offercyclesid
		, ioc.controlgroupid
		, o.IronOfferName
	Into #IORCheckData
	From #IronOffer_Ref_nFI as i
	Left join nFI.Relational.IronOffer_References as a
		on i.ironoffercyclesid = a.ironoffercyclesid
	Left join nFI.Relational.ironoffercycles as ioc
		on i.ironoffercyclesid = ioc.ironoffercyclesid
	Left join nFI.Relational.OfferCycles oc
		on ioc.offercyclesid = oc.OfferCyclesID
	Inner join nFI.Relational.IronOffer as o
		on i.IronOfferID = o.ID
	Left join nFI.Relational.OfferType ot
		on i.OfferTypeID = ot.ID
	Left join nFI.Segmentation.Roc_Shopper_Segment_Types st
		on i.ShopperSegmentID = st.ID
	Where
		oc.StartDate >= (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);


	DELETE
	FROM #IORCheckData
	WHERE IronOfferID = 21942


	-- Load Iron Offers with incorrect segment type assignment due to incorrect naming convention

	Truncate table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_IronOffer_References;

	Insert into Warehouse.Staging.ControlSetup_Validation_nFINonAAM_IronOffer_References
		(PublisherType
		, IronOfferID
		, StartDate
		, EndDate
		, ClubID
		, ironoffercyclesid
		, ShopperSegmentID
		, SegmentName
		, OfferTypeID
		, TypeDescription
		, CashbackRate
		, SpendStretch
		, SpendStretchRate
		, offercyclesid
		, controlgroupid
		, IronOfferName
		)
	Select
		'nFI' as PublisherType
		, d.IronOfferID
		, d.StartDate
		, d.EndDate
		, d.ClubID
		, d.ironoffercyclesid
		, d.ShopperSegmentID
		, d.SegmentName
		, d.OfferTypeID
		, d.TypeDescription
		, d.CashbackRate
		, d.SpendStretch
		, d.SpendStretchRate
		, d.offercyclesid
		, d.controlgroupid
		, d.IronOfferName
	From #IORCheckData d
	Where
		(d.SegmentName is null and d.TypeDescription like ('%Launch%') and d.IronOfferName not like ('%Launch%'))
		or (d.SegmentName is null and d.TypeDescription like ('%Universal%') and d.IronOfferName not like ('%Universal%') and d.IronOfferName not like ('%base%') and d.IronOfferName not like ('%AllSegments%') and d.IronOfferName not like ('%Launch%'))
		or (d.SegmentName is null and d.TypeDescription like ('%Welcome%') and d.IronOfferName not like ('%Welcome%') and d.IronOfferName not like ('%NewJoiner%'))
		or (d.SegmentName like ('%Acquisition%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Acquisition%') and d.IronOfferName not like ('%Acquire%') and d.IronOfferName not like ('%Aquire%'))
		or (d.SegmentName like ('%Grow%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Grow%'))
		or (d.SegmentName like ('%Lapsed%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Lapsed%') and d.IronOfferName not like ('%Winback%'))
		or (d.SegmentName like ('%Retain%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Retain%'))
		or (d.SegmentName like ('%Shopper%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Shopper%') and d.IronOfferName not like ('%Retain&Grow%'))
		or (d.SegmentName like ('%Winback%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Winback%'))
		or (d.SegmentName like ('%Winback Prime%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Winback Prime%') and d.IronOfferName not like ('%WinbackPrime%'));

END