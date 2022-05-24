
-- *******************************************************************************
-- Author: JEA
-- Create date: 03/11/2016
-- Description: Retrieves non-RBS customer data for APW direct load 
-- *******************************************************************************
CREATE PROCEDURE [APW].[DirectLoad_Customer_Fetch]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	cu.FanID
		,	cu.ClubID AS PublisherID
		,	cu.Gender
		,	CASE
				WHEN cup.DOB != '1900-01-01 00:00:00.000'THEN [cup].[DOB]
				ELSE NULL
			END AS DOB
		,	cu.RegistrationDate AS ActivationDate
		,	CONVERT(TINYINT, 0) AS SubPublisherID
	FROM [Derived].[Customer] cu
	INNER JOIN [Derived].[Customer_PII] cup
		ON cu.FanID = cup.FanID
	
END