-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--exec gas.Combination_FetchByIDs '1,2'
-- =============================================
Create PROCEDURE [gas].[Combination_FetchByIDs]
	@IDs VARCHAR(MAX)
AS
BEGIN

      declare @Combination table(
            ID int not null primary key clustered      
      )
	
	  INSERT INTO @Combination(ID)
      select Item from [dbo].[il_SplitStringArray](@IDs,',')

	select * from Staging.Combination lpr 
	INNER JOIN @Combination c ON lpr.CombinationID = c.ID
END
