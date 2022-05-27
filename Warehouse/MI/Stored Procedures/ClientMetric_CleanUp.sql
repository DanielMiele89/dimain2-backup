/***************************************************************************
Author:	Hayden Reid
Date: 17/03/2015
Purpose: Cleans up Client Metric tables after SSIS Data Flow (OPRBS-37)
***************************************************************************/
CREATE PROCEDURE [MI].[ClientMetric_CleanUp]
AS
BEGIN

    DELETE FROM MI.ClientMetric_CampDashboard
    WHERE Retailer IN (' Total', ' Total incl BP', 'Retailer', '') 
	   OR Retailer IS NULL

    DELETE FROM MI.ClientMetric_FinanceXL
    WHERE Dates NOT LIKE '%Overr%'

END



