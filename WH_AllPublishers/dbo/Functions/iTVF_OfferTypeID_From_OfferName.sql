

-- =============================================
-- Author:		Rory Francis
-- Create date: 9th April 2022
-- Description:	Function used to infer Offers Segment from it's name
-- =============================================
CREATE FUNCTION [dbo].[iTVF_OfferTypeID_From_OfferName] (@InputString VARCHAR(4000))
RETURNS TABLE 
AS
RETURN 
(
	SELECT OfferTypeID =	CASE
								WHEN @InputString LIKE '%ShopperRiskOfLapsing%' THEN 19
								WHEN @InputString LIKE '%ShopperGrow%' THEN 20
								WHEN @InputString LIKE '%Acquire' THEN 14 
								WHEN @InputString LIKE '%Lapsed' THEN 14
								WHEN @InputString LIKE '%Lapsers' THEN 14
								WHEN @InputString LIKE '%Shopper' THEN 14
								WHEN @InputString LIKE '%Welcome' THEN 10
								WHEN @InputString LIKE '%Acquire%' THEN 14
								WHEN @InputString LIKE '%Lapsed%' THEN 14
								WHEN @InputString LIKE 'Existing' THEN 14
								WHEN @InputString LIKE '%Lasped%' THEN 14
								WHEN @InputString LIKE '%Lapsed/%' THEN 14
								WHEN @InputString LIKE '%Homemove%' THEN 16
								WHEN @InputString LIKE '%Birthda%' THEN 15
								WHEN @InputString LIKE '%Aqcuire' THEN 14
								WHEN @InputString LIKE '%Nursery' THEN 14
								WHEN @InputString LIKE '%Lapsing' THEN 14
								WHEN @InputString LIKE '%Shopper%' THEN 14
								WHEN @InputString LIKE '%Shopper/%' THEN 14
								WHEN @InputString LIKE '%Retain%' THEN 14
								WHEN @InputString LIKE '%Grow%' THEN 14
								WHEN @InputString LIKE '%Launch%' THEN 11
								WHEN @InputString LIKE '%Joiner%' THEN 10
								WHEN @InputString LIKE '%Sky%MFDD%' THEN 14
								WHEN @InputString LIKE '%Europcar%MFDD%' THEN 14
								
								WHEN @InputString LIKE '%Universal%' THEN 17
								WHEN @InputString LIKE '%Core%' THEN 17
								WHEN @InputString LIKE '%AllMembers%' THEN 17
								WHEN @InputString LIKE '%AllCardholder%' THEN 17
								WHEN @InputString LIKE '%AllCardMember%' THEN 17
								WHEN @InputString LIKE '%AllCustomer%' THEN 17
								WHEN @InputString LIKE '%Base%' THEN 17
								WHEN @InputString LIKE '%Untargeted%' THEN 17
								WHEN @InputString LIKE '%AllSegments%' THEN 17

								ELSE NULL
						END
)
