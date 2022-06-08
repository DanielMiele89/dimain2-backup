-- ============================================================e===================================================
-- Author:		Edmond Eilerts de Haan
-- Create date: 2019-12-16
-- Description: Gathers the member offer data for the given club
-- Jira Ticket : INC-421
-- Change Log:
--
-- =======================================================================================================================
CREATE PROCEDURE [dbo].[MemberOffer_GatherClubData_DBA634]
 @ClubID INT
, @DateDiffFromRunDate INT
, @now DATETIME
, @ChunkSize INT
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- CJM 20210303

BEGIN
	--Gather the data
	INSERT INTO MemberOfferAssociation (OfferID, Priority, PartnerID, PartnerName, SourceUID, StartDate, EndDate)
	select
	io.id as OfferID
	, pcr.Priority
	, p.ID as PartnerID
	, p.name as PartnerName
	, f.SourceUID
	, CAST(CAST(iom.StartDate as DATE) as DATETIME) as StartDate
	, CAST(CAST(iom.EndDate as DATE) as DATETIME) + ' 23:59:59.997' as EndDate
	from SLC_Repl.dbo.club c 
	inner join SLC_Repl.dbo.IronOfferClub ioc on c.id = ioc.ClubID
	inner join SLC_Repl.dbo.ironoffer io on io.id = ioc.IronOfferID
	inner join SLC_Repl.dbo.PartnerCommissionRule pcr on io.id = pcr.RequiredIronOfferID  and pcr.PartnerID = io.PartnerID
			and (pcr.RequiredClubID is null or pcr.RequiredClubID = c.id)
	inner join SLC_Repl.dbo.Partner p on p.id = IO.PartnerID
	inner join SLC_Repl.dbo.fan f on f.clubid = c.id 
	left join SLC_Repl.dbo.IronOfferMember iom on iom.CompositeID = f.compositeid
		and iom.IronOfferID = io.ID
		and iom.StartDate <= DATEADD(dd, @DateDiffFromRunDate, @now)
		and (iom.EndDate >= DATEADD(dd, @DateDiffFromRunDate, @now) or iom.EndDate is null)
	inner join [Warehouse].[Iron].[PrimaryRetailerIdentification] pri on pri.PartnerID = p.ID and pri.PrimaryPartnerID is null
	where c.id = @ClubID
	and (io.EndDate >= DATEADD(dd, @DateDiffFromRunDate, @now) or io.EndDate is null)
	and (pcr.EndDate >= DATEADD(dd, @DateDiffFromRunDate, @now) or pcr.EndDate is null)
	and io.IsSignedOff = 1
	and io.IsAboveTheLine = 0
	and io.IsDefaultCollateral = 0
	and f.status = 1 
	and pcr.Status = 1 
	and pcr.TypeID = 2
	and (iom.CompositeID is not null or io.IsAppliedToAllMembers = 1);

	--Chunk it up
	;WITH PriorityOffers AS (
		SELECT chunk,SourceUID, ROW_NUMBER() OVER(PARTITION BY PartnerID, SourceUID ORDER BY Priority) rnum
		FROM MemberOfferAssociation
	),
	Chunks AS (
       SELECT chunk, newchunk = ((ROW_NUMBER() OVER(ORDER BY (SourceUID))-1) / @ChunkSize)+1
       FROM PriorityOffers
	   WHERE rnum = 1 
	)
	UPDATE Chunks SET chunk = newchunk;
END