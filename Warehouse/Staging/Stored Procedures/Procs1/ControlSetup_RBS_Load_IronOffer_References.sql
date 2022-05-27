/******************************************************************************
Author: Jason Shipp
Created: 15/03/2018
Purpose:
	- Load new entries into Warehouse.Relational.IronOffer_References table
	- Output validation of offer types assigned to the new entries
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_IronOffer_References]

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

	If  object_id ('tempdb..#CashbackRate_Warehouse') is not null drop table #CashbackRate_Warehouse;

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
	Into #CashbackRate_Warehouse
	From Warehouse.Relational.IronOffer_PartnerCommissionRule pcr
	Where
		[Status] = 1
		and typeid = 1
	Group by
		IronOfferID;

	/******************************************************************************
	Generate entries to be added to Warehouse.Relational.IronOffer_References table
	******************************************************************************/

	If object_id ('tempdb..#IronOffer_Ref_Warehouse') is not null drop table #IronOffer_Ref_Warehouse;

	Select	
		i.IronOfferID
		, 132 as ClubID
		, ioc.IronOfferCyclesID
		, s.SegmentID as ShopperSegmentID
		, s.OfferTypeID
		, cb.CashbackRate as CashbackRate
		, cb.BasketSize as SpendStretch
		, cb.SpendStretchCashbackRate as SpendStretchRate
	Into #IronOffer_Ref_Warehouse
	From Warehouse.Relational.ironoffercycles ioc
	Inner join Warehouse.Relational.IronOffer i
		on ioc.Ironofferid = i.IronOfferID
	Inner join #CashbackRate_Warehouse cb
		on i.IronOfferID = cb.IronOfferID
	Inner join #OCs o
		on o.offercyclesid = ioc.Offercyclesid
	Left join Warehouse.Relational.IronOfferSegment s
		on i.IronOfferID = s.IronOfferID;

	/******************************************************************************
	Load new entries into Warehouse.Relational.IronOffer_References table
	******************************************************************************/

	Declare @MaxID int = (Select max(ID) From Warehouse.Relational.IronOffer_References)

	Insert into Warehouse.Relational.IronOffer_References 
	Select
		Row_number() Over(order by r.IronofferID ASC)+@MaxID AS ID
		, r.* 
	From #IronOffer_Ref_Warehouse r
	Left join Warehouse.Relational.IronOffer_References a
		on r.ironoffercyclesid = a.Ironoffercyclesid
	Inner join Warehouse.Relational.ironoffercycles c
		on r.ironoffercyclesID = c.IronOfferCyClesID
	Inner join Warehouse.Relational.IronOffer i
		on r.IronOfferID = i.IronOfferID
	Where
		a.ironoffercyclesid is null;

	/******************************************************************************
	CHECK POINT: Validate entries added to Warehouse.Relational.IronOffer_References table

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_RBS_IronOffer_References
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
		, CONSTRAINT PK_ControlSetup_Validation_RBS_IronOffer_References PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	If object_id ('tempdb..#IORCheckData') is not null drop table #IORCheckData;
	
	Select	
		'Warehouse' as PublisherType
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
	From #IronOffer_Ref_Warehouse as i
	Left join Warehouse.Relational.IronOffer_References as a
		on i.ironoffercyclesid = a.ironoffercyclesid
	Left join Warehouse.Relational.ironoffercycles as ioc
		on i.ironoffercyclesid = ioc.ironoffercyclesid
	Left join Warehouse.Relational.OfferCycles oc
		on ioc.offercyclesid = oc.OfferCyclesID
	Inner join Warehouse.Relational.IronOffer as o
		on i.IronOfferID = o.IronOfferID
	Left join Warehouse.Relational.OfferType ot
		on i.OfferTypeID = ot.ID
	Left join Warehouse.Segmentation.Roc_Shopper_Segment_Types st
		on i.ShopperSegmentID = st.ID
	Where
		oc.StartDate >= (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);

	-- Load Iron Offers with incorrect segment type assignment due to incorrect naming convention

	Truncate table Warehouse.Staging.ControlSetup_Validation_RBS_IronOffer_References;

	Insert into Warehouse.Staging.ControlSetup_Validation_RBS_IronOffer_References
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
		'Warehouse' as PublisherType
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
		or (d.SegmentName like ('%Acquisition%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Acquisition%') and d.IronOfferName not like ('%Acquire%') and d.IronOfferName not like ('%Aquire%') and d.IronOfferName not like ('%Aqcuire%') and d.IronOfferName not like ('%MFDD%') and d.IronOfferName not like ('%lapsing%'))
		or (d.SegmentName like ('%Grow%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Grow%'))
		or (d.SegmentName like ('%Lapsed%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Lapsed%') and d.IronOfferName not like ('%Winback%'))
		or (d.SegmentName like ('%Retain%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Retain%'))
		or (d.SegmentName like ('%Shopper%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Shopper%') and d.IronOfferName not like ('%Retain&Grow%') and d.IronOfferName not like ('%Nursery%') and d.IronOfferName not like ('%Nursey%')  and d.IronOfferName not like ('%Lapsing%') and d.IronOfferName not like ('%MFDD%') AND d.IronOfferID NOT IN (22202, 22203))
		or (d.SegmentName like ('%Winback%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Winback%'))
		or (d.SegmentName like ('%Winback Prime%') and d.TypeDescription like ('%ShopperSegment%') and d.IronOfferName not like ('%Winback Prime%') and d.IronOfferName not like ('%WinbackPrime%'));

END