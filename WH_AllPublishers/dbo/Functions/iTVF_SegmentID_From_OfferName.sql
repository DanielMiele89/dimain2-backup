

-- =============================================
-- Author:		Rory Francis
-- Create date: 9th April 2022
-- Description:	Function used to infer Offers Segment from it's name
-- =============================================
CREATE FUNCTION [dbo].[iTVF_SegmentID_From_OfferName] (@InputString VARCHAR(4000))
RETURNS TABLE 
AS
RETURN 
(
	SELECT SegmentID =	CASE
							WHEN @InputString LIKE '%Universal%' THEN 0
							WHEN @InputString LIKE '%AllMembers%' THEN 0
							WHEN @InputString LIKE '%AllCardholder%' THEN 0
							WHEN @InputString LIKE '%AllCardMember%' THEN 0
							WHEN @InputString LIKE '%AllCustomer%' THEN 0
							WHEN @InputString LIKE '%Existing%' THEN 9
							WHEN @InputString LIKE '%Lapsed' THEN 8
							WHEN @InputString LIKE '%ShopperRiskOfLapsing%' THEN 10
							WHEN @InputString LIKE '%ShopperGrow%' THEN 11
							WHEN @InputString LIKE '%Acquire' THEN 7 
							WHEN @InputString LIKE '%Shopper' THEN 9
							WHEN @InputString LIKE '%Acqui%' THEN 7
							WHEN @InputString LIKE '%Lapsed%' THEN 8
							WHEN @InputString LIKE '%Lapsed/%' THEN 8
							WHEN @InputString LIKE '%Lasped%' THEN 8
							WHEN @InputString LIKE '%Lapsers' THEN 8
							WHEN @InputString LIKE '%Welcome' THEN NULL
							WHEN @InputString LIKE '%Homemover' THEN NULL
							WHEN @InputString LIKE '%Birthday' THEN NULL
							WHEN @InputString LIKE '%Lapsing%' THEN 9
							WHEN @InputString LIKE '%Shopper%' THEN 9
							WHEN @InputString LIKE '%Shopper/%' THEN 9
							WHEN @InputString LIKE '%Existing' THEN 9			
							WHEN @InputString LIKE '%Retain%' THEN 6
							WHEN @InputString LIKE '%Grow%' THEN 5
							WHEN @InputString LIKE '%Prime%' THEN 4
							WHEN @InputString LIKE '%WinBack%' THEN 3
							WHEN @InputString LIKE '%LowInterest%' THEN 1
							WHEN @InputString LIKE '%Sky%MFDD%' THEN 7	
							WHEN @InputString LIKE '%Europcar%MFDD%' THEN 7
							ELSE NULL
						END
)
