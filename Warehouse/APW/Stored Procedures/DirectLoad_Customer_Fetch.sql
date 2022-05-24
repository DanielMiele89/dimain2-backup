-- =============================================
-- Author:		JEA
-- Create date: 03/11/2016
-- Description:	Retrieves customers from staging area for direct load
-- =============================================
CREATE PROCEDURE [APW].[DirectLoad_Customer_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT FanID
		, CAST(132 AS tinyint) AS PublisherID
		, DOB
		, Gender
		, ActivationDate
		, DeactivationDate
		, CAST(0 AS TINYINT) AS SubPublisherID
	FROM APW.DirectLoad_Staging_Customer

END
