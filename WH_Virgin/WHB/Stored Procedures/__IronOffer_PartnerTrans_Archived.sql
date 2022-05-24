﻿
/*
-- Replaces this bunch of stored procedures:
EXEC WHB.IronOfferPartnerTrans_Outlet_V1_5
EXEC WHB.IronOfferPartnerTrans_IronOffer_V1_2
EXEC WHB.IronOfferPartnerTrans_IronOfferMembers_DailySmallLoad_V2
EXEC WHB.IronOfferPartnerTrans_IronWelcomeOffer_Update
EXEC WHB.IronOfferPartnerTrans_PartnerTrans_V1_8_Append
EXEC WHB.IronOfferPartnerTrans_PartnerTrans_CardType_V1
EXEC WHB.IronOfferPartnerTrans_Corrections_V1_7
EXEC WHB.IronOfferPartnerTrans_PartnerCommissionRule
EXEC WHB.IronOfferPartnerTrans_Update_BaseAndNonCore_StartEndDates
*/

CREATE PROCEDURE [WHB].[__IronOffer_PartnerTrans_Archived] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @msg VARCHAR(200), @RowsAffected INT




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_Outlet_V1_5 ##################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_Outlet_V1_5', 'Starting'

TRUNCATE TABLE staging.Outlet
INSERT INTO	staging.Outlet
SELECT	ro.ID as OutletID,
		ro.PartnerID,
		ro.MerchantID,
		ro.Channel,					--1 = Online, 2 = Offline
		LTRIM(RTRIM(f.Address1))				as Address1,
		LTRIM(RTRIM(f.Address2))				as Address2,
		LTRIM(RTRIM(f.City))					as City,		
		LEFT(ltrim(rtrim(f.PostCode)),10)		as Postcode,
		Cast(Null as varchar(6))				as PostalSector,
		Cast(Null as varchar(2))				as PostArea,
		Cast(Null as varchar(30))				as Region,
		Cast(null as bit)						as IsOnline
FROM SLC_Report.dbo.RetailOutlet ro 
LEFT JOIN SLC_Report.dbo.Fan f  
	on ro.FanID = f.ID
INNER JOIN Derived.[Partner] p  
	on ro.PartnerID = p.PartnerID


--Enhance Data in Staging - Start - Outlet
UPDATE staging.Outlet
set	PostalSector =	
			Case
				When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][a-z][a-z]' Then
						Left(replace(replace(PostCode,char(160),''),' ',''),2)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),3),1)
				When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][0-9][a-z][a-z]' or
						replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][a-z][a-z]' or 
						replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][a-z][0-9][a-z][a-z]' Then 
						Left(replace(replace(PostCode,char(160),''),' ',''),3)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),4),1)
				When replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' or
						replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'Then 
						Left(replace(replace(PostCode,char(160),''),' ',''),4)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),5),1)
				Else ''
			End,
	PostArea =		
			case 
				when PostCode like '[A-Z][0-9]%' then left(PostCode,1) 
				else left(PostCode,2) 
			end,
	IsOnline =		
			case 
				when Channel = 1 then 1 
				else 0 
			end		--Channel = 1 represents an online outlet

update	staging.Outlet
set		staging.Outlet.Region = Staging.PostArea.Region
from	staging.Outlet 
inner join Staging.PostArea on staging.Outlet.PostArea = Staging.PostArea.PostAreaCode


-- Build final tables in relational schema - Outlet 
TRUNCATE TABLE Derived.Outlet
INSERT INTO Derived.Outlet
SELECT	OutletID,
	IsOnline,
	MerchantID,
	PartnerID,
	Address1,
	Address2,
	City,
	PostCode,
	PostalSector,
	PostArea,
	Region
FROM Staging.Outlet 

EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_Outlet_V1_5', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_IronOffer_V1_2 ###############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_IronOffer_V1_2', 'Starting'
EXEC WHB.IronOfferPartnerTrans_IronOffer_V1_2
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_IronOffer_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_IronOfferMembers_DailySmallLoad_V2 ###########
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_IronOfferMembers_DailySmallLoad_V2', 'Starting'
EXEC WHB.IronOfferPartnerTrans_IronOfferMembers_DailySmallLoad_V2
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_IronOfferMembers_DailySmallLoad_V2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_IronWelcomeOffer_Update ######################
-- Not required in this implementation - see generic WH build in Warehouse db
-------------------------------------------------------------------------------




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_PartnerTrans_V1_8_Append #####################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_PartnerTrans_V1_8_Append', 'Starting'
EXEC WHB.IronOfferPartnerTrans_PartnerTrans_V1_8_Append
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_PartnerTrans_V1_8_Append', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_PartnerTrans_CardType_V1 #####################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_PartnerTrans_CardType_V1', 'Starting'

Update pt
Set PaymentMethodID =	Case
							When CardTypeID = 1 then 1 -- Credit Card
							When CardTypeID = 2 then 0 -- Debit Card
							Else 3
						End
from relational.PartnerTrans as pt 
inner join SLC_Report..Trans as t 
	on pt.MatchID = t.MatchID
inner join Slc_report.dbo.Pan as p 
	on t.PanID = p.id
inner join slc_Report..PaymentCard as pc 
	on p.PaymentCardID = pc.ID
Where pc.CardTypeid <> 2

EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_PartnerTrans_CardType_V1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_Corrections_V1_7 #############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_Corrections_V1_7', 'Starting'

UPDATE c
	SET MarketableByEmail = 1 -----------Update MarketableByEmail which makes it selectable for campaigns
FROM Derived.Customer as c
WHERE c.LaunchGroup in ('Init','STF1','STF2') 
	and c.[Status] = 1  ----------------Customer is still active on the scheme
	and c.EmailStructureValid = 1  ---Email address is valid
	and MarketableByEmail = 0 -----------Check they are currently not emailable


--Update Staging.PartnerTrans with corrections---------------------------
--Updates Staging.PartnerTrans by changing the Added Date to that of the File imported date
UPDATE pt
SET AddedDate = a.AddedDate
FROM Derived.PartnerTrans as pt
INNER JOIN Warehouse.Staging.Correction_Cineworld as a
	ON pt.matchid = a.matchid


--Declare @RecordCount int
--Set @RecordCount = (Select Count(*) from Relational.Customer as c where c.MarketableByEmail = 1 and c.SourceUID in (Select SourceUID  from Staging.Customer_DuplicateSourceUID))
UPDATE Derived.Customer
Set   MarketableByEmail = 0
Where MarketableByEmail = 1 
and SourceUID in (Select SourceUID  from Staging.Customer_DuplicateSourceUID)


--Populate PartnerTrans AboveBase field----------------------------------
UPDATE Derived.Partnertrans
	SET AboveBase = 0
WHERE AboveBase is null 
	AND Cast(CashbackEarned as real) / TransactionAmount Between -.0125 and .0125

UPDATE pt
	SET AboveBase = 0
FROM Derived.PartnerTrans as pt
INNER JOIN [Derived].[Partner_NonCoreBaseOffer] as n
	on pt.IronOfferID = n.IronOfferID

EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_Corrections_V1_7', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_PartnerCommissionRule ########################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_PartnerCommissionRule', 'Starting'

--Reload PartnerCommissionRule Data----------
TRUNCATE TABLE Derived.IronOffer_PartnerCommissionRule
INSERT INTO Derived.IronOffer_PartnerCommissionRule
SELECT ID as PCR_ID,
	PartnerID,
	TypeID,
	CommissionRate,
	Status,
	Priority,
	DeletionDate,
	MaximumUsesPerFan as MaximumUsesPerFan,
	RequiredNumberOfPriorTransactions as NumberofPriorTransactions,
	RequiredMinimumBasketSize as MinimumBasketSize,
	RequiredMaximumBasketSize as MaximumBasketSize,
	RequiredChannel as Channel,
	RequiredClubID as ClubID,
	RequiredIronOfferID as IronOfferID,
	RequiredRetailOutletID as OutletID,
	RequiredCardholderPresence as CardHolderPresence
FROM SLC_Report..PartnerCommissionRule
WHERE RequiredIronOfferID IS NOT NULL


-- Insert PCR rules for MFDD
INSERT INTO Derived.IronOffer_PartnerCommissionRule_MFDD (IronOfferID)
SELECT io.IronOfferID
FROM derived.IronOffer io
INNER JOIN (
	SELECT 
		IronOfferID,
		PartnerID
	FROM Derived.IronOffer 
	WHERE (EndDate IS NULL OR EndDate >= GETDATE())
		AND IsTriggerOffer = 0
		AND IronOfferName LIKE '%MFDD%'
) p 
	ON io.PartnerID = p.PartnerID
WHERE io.IronOfferName like '%MFDD%'
	AND NOT EXISTS (SELECT 1 FROM Derived.IronOffer_PartnerCommissionRule_MFDD mfdd WHERE mfdd.ironofferid = io.IronOfferID)


EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_PartnerCommissionRule', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.IronOfferPartnerTrans_Update_BaseAndNonCore_StartEndDates ##########
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_Update_BaseAndNonCore_StartEndDates', 'Starting'


-- Update PartnerOffers_Base Table**************
UPDATE pob
	SET StartDate = io.StartDate, 
		EndDate = io.EndDate
FROM Derived.PartnerOffers_Base pob
INNER JOIN Derived.IronOffer io
	ON pob.OfferID = io.IronOfferID

--Update Partner_BaseOffer Table**************
UPDATE pob
	SET StartDate = io.StartDate,
		EndDate = io.EndDate
FROM Derived.Partner_BaseOffer pob
INNER JOIN Derived.IronOffer io
	ON pob.OfferID = io.IronOfferID
	
--Update Partner_NonCoreBaseOffer**************
UPDATE ncb
	SET StartDate = io.StartDate,
		EndDate = io.EndDate
FROM Derived.Partner_NonCoreBaseOffer ncb
INNER JOIN Derived.IronOffer io
	ON ncb.IronOfferID = io.IronOfferID

EXEC Monitor.ProcessLog_Insert 'WHB', 'IronOfferPartnerTrans_Update_BaseAndNonCore_StartEndDates', 'Finished'




RETURN 0