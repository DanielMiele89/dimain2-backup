

-- =============================================
-- Author:		Rory Francis
-- Create date: 9th April 2022
-- Description:	Function used to infer Offers Segment from it's name
-- =============================================
CREATE FUNCTION [dbo].[iTVF_SegmentCode_From_OfferName] (@InputString VARCHAR(4000))
RETURNS TABLE 
AS
RETURN 
(
	SELECT SegmentCode =	CASE
								WHEN @InputString LIKE '%Welcome%' THEN 'A'
								WHEN @InputString LIKE '%Homemover%' THEN 'B'
								WHEN @InputString LIKE '%Birthday%' THEN 'B'
								WHEN @InputString LIKE '%Universal%' THEN 'B'
								WHEN @InputString LIKE '%HomeMover%' THEN 'B'
								WHEN @InputString LIKE '%Base%' THEN 'B'
								WHEN @InputString LIKE '%Launch%' THEN 'B'
								ELSE NULL
							END
)
