-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[IronOfferSegment_Fetch]
	
AS
BEGIN
	SET NOCOUNT ON;

    SELECT IronOfferID
		, OfferStartDate
		, OfferEndDate
		, PartnerID
		, RetailerID
		, IronOfferName
		, PublisherGroupID
		, PublisherGroupName
		, SegmentID
		, SegmentName
		, SegmentCode
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, OfferTypeDescription
		, OfferTypeForReports
		, DateAdded
	FROM Relational.IronOfferSegment

END
