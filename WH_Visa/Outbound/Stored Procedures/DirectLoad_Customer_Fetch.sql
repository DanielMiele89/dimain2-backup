-- =============================================
-- Author:		JEA
-- Create date: 31/10/2016
-- Description:	slc_report staging customer load
-- =============================================
CREATE PROCEDURE [Outbound].[DirectLoad_Customer_Fetch]
AS
BEGIN

	SET NOCOUNT ON;

	SELECT	FanID = fa.ID
		,	CustStatus = COALESCE(cu.CurrentlyActive, 1)
		,	DOB = COALESCE(cup.DOB, fa.DOB)
		,	ActivatedDate = CONVERT(DATE, COALESCE(cu.RegistrationDate, fa.RegistrationDate))
		,	Gender = CONVERT(CHAR(1), cu.Gender)
		,	DeactivatedDate = cu.DeactivatedDate
		,	PublisherID = fa.ClubID
		,	SubPublisherID = 0
	FROM [SLC_Report].[dbo].[Fan] fa
	LEFT JOIN [WH_Virgin].[Derived].[Customer] cu
		ON fa.ID = cu.FanID
	LEFT JOIN [WH_Virgin].[Derived].[Customer_PII] cup
		ON fa.ID = cup.FanID
	WHERE fa.ClubID = 166

END
