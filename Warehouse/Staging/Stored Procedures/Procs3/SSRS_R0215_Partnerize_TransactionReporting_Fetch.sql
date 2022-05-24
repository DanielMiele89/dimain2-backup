CREATE PROCEDURE [Staging].[SSRS_R0215_Partnerize_TransactionReporting_Fetch] (@RetailerId int, @CamRef varchar(50), @CampaignId VARCHAR(50))
	
AS
BEGIN
	
	 SET NOCOUNT ON;

	 /*
	 DECLARE @RetailerId INT = 4117, -- M&M Direct
	         @PublisherId VARCHAR(50) = '1011l89145',
	 		 @CampaignId VARCHAR(50) =	'1100l607',
	 		 @CamRef VARCHAR(50) = '1011lfWTZ'
	--		 @ReturnsOnly BIT =0;
	*/

	 --Declare Date Variables used in query
	 DECLARE @StartDate DATE = DATEADD(MM,DATEDIFF(MM,0,DATEADD(MM,-1,GETDATE())),0)
	 DECLARE @EndDate DATE = DATEADD(MM,DATEDIFF(MM,0,DATEADD(MM,0,GETDATE())),-1)
	 DECLARE @Now datetime = GETDATE();

	 --PRINT @StartDate;
	 --PRINT @EndDate;

	SELECT	
	--Transactions
		@CampaignId as campaign_id,
		@CamRef as camref,
		pt.TransactionDate AS conversion_time,
		CONVERT(BIGINT, pt.ID) * -1 AS conversionref,
		'GB' AS country,
		'GBP' AS currency,
		--'CPA' as conversion_type,
		pt.Price as value,
	    pt.GrossAmount AS commission,
		CASE WHEN pt.MaskedCardNumber IS NOT NULL THEN CONCAT(RIGHT(pt.MaskedCardNumber,4),'-NULL') ELSE NULL END AS adref,
		'Card%20Linked' as tsource
	FROM SLC_REPL.RAS.PANless_Transaction pt
	INNER JOIN SLC_REPL..CRT_File fi
		ON pt.FileID = fi.ID
	LEFT JOIN SLC_REPL..RetailOutlet ro
		ON pt.MerchantNumber = ro.MerchantID
	WHERE pt.PartnerID = @RetailerId
	AND (pt.TransactionDate BETWEEN @StartDate AND @EndDate)-- OR pt.AddedDate BETWEEN @StartDate AND @EndDate)
	AND fi.MatcherShortName NOT IN ('VGN', 'AMX', 'VSI', 'VSA')	--	Excluded as these are included in SchemeTrans
	AND pt.GrossAmount>0
	UNION
	SELECT	
	--Returns
		@CampaignId as campaign_id,
		@CamRef as camref,
		pt.TransactionDate AS conversion_time,
		CONVERT(BIGINT, pt.ID) * -1 AS conversionref,
		'GB' AS country,
		'GBP' AS currency,
		--'CPA' as conversion_type,
		pt.Price * -1 as value,
	    pt.GrossAmount * -1 AS commission,
		CASE WHEN pt.MaskedCardNumber IS NOT NULL THEN CONCAT(RIGHT(pt.MaskedCardNumber,4),'-NULL') ELSE NULL END AS adref,
		'Card%20Linked' as tsource
	FROM SLC_REPL.RAS.PANless_Transaction pt
	INNER JOIN SLC_REPL..CRT_File fi
		ON pt.FileID = fi.ID
	LEFT JOIN SLC_REPL..RetailOutlet ro
		ON pt.MerchantNumber = ro.MerchantID
	WHERE pt.PartnerID = @RetailerId
	AND (pt.TransactionDate BETWEEN @StartDate AND @EndDate)-- OR pt.AddedDate BETWEEN @StartDate AND @EndDate)
	AND fi.MatcherShortName NOT IN ('VGN', 'AMX', 'VSI', 'VSA')	--	Excluded as these are included in SchemeTrans
	AND pt.GrossAmount<0
	--ORDER BY TransactionDate
	
END