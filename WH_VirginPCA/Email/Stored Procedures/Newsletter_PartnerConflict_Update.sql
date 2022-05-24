/*

	Author:		Stuart Barnley

	Date:		24th July 2017

	Purpose:	To turn on or off rules based on Merchants included 
				in the OPE

*/
CREATE PROCEDURE [Email].[Newsletter_PartnerConflict_Update] (@Email DATE)

AS

BEGIN

-----------------------------------------------------------------------------------------------
---------------Count the number of partners included in OPE for each rule----------------------
-----------------------------------------------------------------------------------------------

	--	DECLARE @Email DATE = '2019-06-06'

	IF OBJECT_ID('tempdb..#OfferPrioritisation') IS NOT NULL DROP TABLE #OfferPrioritisation
	SELECT DISTINCT
		   PartnerID
	INTO #OfferPrioritisation
	FROM [Email].[Newsletter_OfferPrioritisation] op
	WHERE op.EmailDate = @Email
	
	IF OBJECT_ID('tempdb..#Rules') IS NOT NULL DROP TABLE #Rules
	SELECT DISTINCT
		   pc.RuleID
		 , pc.PartnerID
		 , 1 AS LiveRule
	INTO #Rules
	FROM (	SELECT pc.RuleID
				 , pc.PartnerID
				 , pc.MaxMembershipsCount
				 , COUNT(1) OVER (PARTITION BY pc.RuleID) AS PartnersLive
			FROM [Email].[Newsletter_PartnerConflict] pc
			WHERE pc.EndDate IS NULL
			AND EXISTS (SELECT 1
						FROM #OfferPrioritisation op
						WHERE pc.PartnerID = op.PartnerID)) pc
	WHERE pc.PartnersLive > pc.MaxMembershipsCount


	IF OBJECT_ID('tempdb..#OldRules') IS NOT NULL DROP TABLE #OldRules
	SELECT RuleID
		 , pc.MaxMembershipsCount
		 , COUNT(DISTINCT op.PartnerID) AS Partners
	INTO #OldRules
	FROM [Email].[Newsletter_PartnerConflict] pc
	INNER JOIN [Email].[Newsletter_OfferPrioritisation] op
		ON pc.PartnerID = op.PartnerID
		AND op.EmailDate = @Email
		AND pc.EndDate IS NULL
	GROUP BY pc.RuleID
		   , pc.MaxMembershipsCount
	HAVING COUNT(DISTINCT op.PartnerID) > pc.MaxMembershipsCount

-----------------------------------------------------------------------------------------------
---------------------Turn LiveRule on or off based on partners included------------------------
-----------------------------------------------------------------------------------------------

	UPDATE pc
	SET pc.LiveRule = COALESCE(ru.LiveRule, 0)
	FROM [Email].[Newsletter_PartnerConflict] pc
	LEFT JOIN #Rules ru
		ON pc.RuleID = ru.RuleID
		AND pc.PartnerID = ru.PartnerID
	WHERE pc.EndDate IS NULL

	UPDATE pc
	SET pc.LiveRule = COALESCE(ru.Partners / ru.Partners, 0)
	FROM [Email].[Newsletter_PartnerConflict] pc
	LEFT JOIN #OldRules ru
		ON pc.RuleID = ru.RuleID

END

