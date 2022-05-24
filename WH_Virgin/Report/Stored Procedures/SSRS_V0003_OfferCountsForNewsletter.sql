

CREATE PROCEDURE [Report].[SSRS_V0003_OfferCountsForNewsletter] (@LionSendID INT)

AS
BEGIN

	--DECLARE @LionSendID INT = 746

	DECLARE @LSID INT = @LionSendID
		  , @EmailDate DATE

	IF @LSID IS NULL
		BEGIN
			SELECT @LSID = MIN([nr].[LionSendID])
			FROM [Email].[NewsletterReporting] nr
			WHERE [nr].[ReportSent] = 0
			AND [nr].[ReportName] = 'SSRS_V0003_OfferCountsForNewsletter'
		END

	SELECT @EmailDate = MAX([Email].[NominatedLionSendComponent].[StartDate])
	FROM [Email].[NominatedLionSendComponent]
	WHERE [Email].[NominatedLionSendComponent].[LionSendID] = @LSID


	SELECT [pvt].[ItemID]
		 , [pvt].[PartnerName]
		 , [pvt].[OfferType]
		 , [pvt].[OfferName]
		 , [pvt].[StartDate]
		 , [pvt].[EndDate]
		 , COALESCE([pvt].[1], 0) AS [Hero Slot]
		 , COALESCE([pvt].[2], 0) AS [Slot 1]
		 , COALESCE([pvt].[3], 0) AS [Slot 2]	
		 , COALESCE([pvt].[4], 0) AS [Slot 3]
		 , COALESCE([pvt].[5], 0) AS [Slot 4]
		 , COALESCE([pvt].[6], 0) AS [Slot 5]
		 , COALESCE([pvt].[7], 0) AS [Slot 6]
		 , COALESCE([pvt].[8], 0) AS [Slot 7]
		 , COALESCE([pvt].[9], 0) AS [Slot 8]
		 , @EmailDate AS EmailDate
		 , @LSID AS LionSendID
	FROM (	SELECT [nlsc].[ItemRank]
				 , nlsc.ItemID
				 , pa.PartnerName
				 , 'Earn' AS OfferType
				 , iof.IronOfferName AS OfferName
				 , iof.StartDate
				 , iof.EndDate
				 , COUNT([nlsc].[CompositeID]) AS Customers	
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
		   , [pvt].[PartnerName]
		   , OfferName

	UPDATE [Email].[NewsletterReporting]
	SET [Email].[NewsletterReporting].[ReportSent] = 1
	WHERE [Email].[NewsletterReporting].[ReportSent] = 0
	AND [Email].[NewsletterReporting].[ReportName] = 'SSRS_V0003_OfferCountsForNewsletter'
	AND [Email].[NewsletterReporting].[LionSendID] = @LSID

END