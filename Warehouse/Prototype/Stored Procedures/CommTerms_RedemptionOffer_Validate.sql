CREATE PROCEDURE [Prototype].[CommTerms_RedemptionOffer_Validate]
AS
	BEGIN

		/*
		validation
		SELECT *
		FROM Prototype.staging_commercialterms_Redemptions
		*/

--SELECT DISTINCT
--	   ctr.ID
--	 , ctr.Retailer
--	 , pa.Name
--FROM Prototype.staging_commercialterms_Redemptions ctr
--LEFT JOIN SLC_Report..Partner pa
--	ON ctr.Retailer LIKE '%' + pa.Name + '%'
--	AND pa.Name != ''



--SELECT *
--FROM Prototype.staging_commercialterms_Redemptions_Dates

		/*
		Insert
		INSERT INTO [Prototype].[commercialterms_Redemptions]
		SELECT *
		FROM [Prototype].[staging_commercialterms_Redemptions]
		*/

		SELECT 1 WHERE 1 = 2
	END