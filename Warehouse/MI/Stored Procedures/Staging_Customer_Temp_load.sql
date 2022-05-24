
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<loads MI.Staging_Customer_Temp >
-- =============================================
CREATE PROCEDURE [MI].[Staging_Customer_Temp_load] (@DateID int)
	-- Add the parameters for the stored procedure here
	WITH EXECUTE AS OWNER
AS
BEGIN


DECLARE @i INT, 
@DateID2 INT, @PartnerID INT, @CumulativetypeID INT , @ClientServiceRef nvarchar(30)

SET @i=1
WHILE @i<=(SELECT MAX(ID) FROM MI.WorkingCumlDates)
BEGIN
    SELECT @DateID2=DateID, @CumulativetypeID=Cumlitivetype, 
    @PartnerID=PartnerID,  @ClientServiceRef=ClientServicesref
    FROM MI.WorkingCumlDates
    WHERE ID=@i 

    IF @ClientServiceRef<>'0' AND @DateID2=@DateID AND @CumulativetypeID=2
    BEGIN 
    EXEC [MI].[Staging_Customer_TempMONLandNonCore_NONcore_load] @DateID , @PartnerID ,  @ClientServiceRef 
    END

    IF @ClientServiceRef='0' AND @DateID2=@DateID AND @CumulativetypeID=2
    BEGIN 
    EXEC [MI].[Staging_Customer_TempMONLandNonCore_CORE_load] @DateID , @PartnerID 
    END

    IF  @DateID2=@DateID AND @CumulativetypeID=2
    BEGIN 
    EXEC [MI].[Staging_Control_Temp_load] @DateID , @PartnerID ,  @ClientServiceRef 
    END

    SET @i=@i+1
END

ALTER INDEX ALL ON MI.Staging_Customer_Temp REBUILD
ALTER INDEX ALL ON MI.Staging_Control_Temp REBUILD

END
