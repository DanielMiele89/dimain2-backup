-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--exec gas.LivePartnerReview_FetchByIDs '1,2'
-- =============================================
CREATE PROCEDURE [gas].[LivePartnerReview_FetchByIDs]
	@IDs VARCHAR(MAX)
AS
BEGIN

      declare @LivePartner table(
            ID int not null primary key clustered      
      )
	
	  INSERT INTO @LivePartner(ID)
      select Item from [dbo].[il_SplitStringArray](@IDs,',')

	select * from Staging.LivePartnerReview lpr 
	INNER JOIN @LivePartner lp ON lpr.LivePartnerReviewID = lp.ID
END