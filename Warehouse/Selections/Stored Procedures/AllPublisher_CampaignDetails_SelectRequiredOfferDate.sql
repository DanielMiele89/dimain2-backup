
CREATE PROCEDURE [Selections].[AllPublisher_CampaignDetails_SelectRequiredOfferDate] @EmailDate DATE
AS
	BEGIN

		/*******************************************************************************************************************************************
			1. Remove entries that aren't of the requied date
		*******************************************************************************************************************************************/

			--DECLARE @EmailDate DATE = '2019-11-21'

			DELETE
			FROM Selections.AllPublisher_CampaignDetails_BriefsToImport
			WHERE CONVERT(DATE, StartDate, 103) != @EmailDate

	END