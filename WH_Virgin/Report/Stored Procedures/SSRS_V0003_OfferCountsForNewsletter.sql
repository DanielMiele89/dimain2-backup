

CREATE PROCEDURE [Report].[SSRS_V0003_OfferCountsForNewsletter] (@LionSendID INT)

AS
BEGIN

	--DECLARE @LionSendID INT = 746

	DECLARE @LSID INT = @LionSendID
		  , @EmailDate DATE

	IF @LSID IS NULL
		BEGIN
			SELECT @LSID = MIN(LionSendID)
			FROM [Email].[NewsletterReporting] nr
			WHERE ReportSent = 0
			AND ReportName = 'SSRS_V0003_OfferCountsForNewsletter'
		END

	SELECT @EmailDate = MAX(StartDate)
	FROM [Email].[NominatedLionSendComponent]
	WHERE LionSendID = @LSID


	SELECT ItemID
		 , PartnerName
		 , OfferType
		 , OfferName
		 , StartDate
		 , EndDate
		 , COALESCE([1], 0) AS [Hero Slot]
		 , COALESCE([2], 0) AS [Slot 1]
		 , COALESCE([3], 0) AS [Slot 2]	
		 , COALESCE([4], 0) AS [Slot 3]
		 , COALESCE([5], 0) AS [Slot 4]
		 , COALESCE([6], 0) AS [Slot 5]
		 , COALESCE([7], 0) AS [Slot 6]
		 , COALESCE([8], 0) AS [Slot 7]
		 , COALESCE([9], 0) AS [Slot 8]
		 , @EmailDate AS EmailDate
		 , @LSID AS LionSendID
	FROM (	SELECT ItemRank
				 , nlsc.ItemID
				 , pa.PartnerName
				 , 'Earn' AS OfferType
				 , iof.IronOfferName AS OfferName
				 , iof.StartDate
				 , iof.EndDate
				 , COUNT(CompositeID) AS Customers	
			FROM [Email].[NominatedLionSendComponent] nlsc
			LEFT JOIN [Derived].[IronOffer] iof
				ON nlsc.ItemID = iof.IronOfferID
			LEFT JOIN [Derived].[Partner] pa 
				ON iof.PartnerID = pa.PartnerID
			WHERE nlsc.LionSendID = @LSID 
			GROUP BY nlsc.ItemRank
				   , nlsc.ItemID
				   , pa.PartnerName
				   , iof.IronOfferName
				   , iof.StartDate
				   , iof.EndDate) [all]
	PIVOT (SUM(Customers) FOR ItemRank IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])) AS pvt
	ORDER BY OfferType
		   , PartnerName
		   , OfferName

	UPDATE [Email].[NewsletterReporting]
	SET ReportSent = 1
	WHERE ReportSent = 0
	AND ReportName = 'SSRS_V0003_OfferCountsForNewsletter'
	AND LionSendID = @LSID

END