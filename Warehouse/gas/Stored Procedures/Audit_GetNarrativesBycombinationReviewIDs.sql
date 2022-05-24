CREATE PROCEDURE [GAS].[Audit_GetNarrativesBycombinationReviewIDs]
		@CombinationReviewIdList VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @CombinationReviewData table(
		CombinationReviewID int not null primary key clustered	
	)
	
	select @CombinationReviewIdList = replace(replace(replace(replace(@CombinationReviewIdList,char(13)+char(10),''),char(10),''),char(13),''),char(10)+char(13),'')
	
	--convert the delimited array of MatchIDs to table
	INSERT INTO @CombinationReviewData(CombinationReviewID)
	SELECT Item FROM [dbo].[il_SplitStringArray](@CombinationReviewIdList,',')
	
	-- Returned Id as well to generate entity class with IAuditable interface & [AuditIdentifier] attribute from complex type.
    SELECT cr.CombinationReviewID, cr.CombinationReviewID as Id,cr.Narrative as NarrativeDesc FROM staging.CombinationReview cr
        INNER JOIN @CombinationReviewData crd ON cr.CombinationReviewID = crd.CombinationReviewID
 

END