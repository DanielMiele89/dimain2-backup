-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--exec gas.CombinationReview_FetchByIDs '3,767;5,767;'
-- =============================================
CREATE PROCEDURE [gas].[CombinationReview_FetchByIDs]
	@Changes VARCHAR(MAX)
AS
BEGIN
	--table for accepted rows
    DECLARE @ChangeTable TABLE(CombinationReviewID INT PRIMARY KEY
		, BrandID SMALLINT)
		
	--collect set of accepted values
		INSERT INTO @ChangeTable
		SELECT LeftItem, RightItem
		FROM dbo.SplitWithPairs(@Changes, ';', ',')
		ORDER BY LeftItem;	
	
	select * from Staging.CombinationReview cr
	INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID
END
