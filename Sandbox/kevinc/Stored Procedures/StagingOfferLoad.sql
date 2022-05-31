
CREATE PROC [kevinc].[StagingOfferLoad]
AS

SET NOCOUNT ON;

	--IF OBJECT_ID('kevinc.StagingOffer') IS NOT NULL
	--DROP TABLE kevinc.StagingOffer;
	--CREATE TABLE kevinc.StagingOffer(
	--	ReportingOfferID	INT NOT NULL,
	--	IronOfferID			INT NOT NULL, --Shoudl this be an IDENTITY column?
	--	OfferTypeID			INT NOT NULL,
	--	PublisherID			INT NOT NULL,
	--	StartDate			DATE,
	--	EndDate				DATE,
	--	PartnerID			INT NOT NULL
	--)

	----CREATE CLUSTERED INDEX StagingOffer_PartnerId_StartDate_EndDate ON kevinc.StagingOffer(PartnerID, StartDate, EndDate)

	INSERT INTO kevinc.StagingOffer([ReportingOfferID], [IronOfferID], [OfferTypeID], [PublisherID], [StartDate], [EndDate], [PartnerID])
	SELECT [ReportingOfferID], [IronOfferID], [OfferTypeID], [PublisherID], [StartDate], [EndDate], [PartnerID] 
	FROM kevinc.ReportingOffer o
	/*Add in clause so that we don't pull offers taht have already been reported.*/

