/**************************************************************************
-- Author: Jason Shipp
-- Create date: 25/01/2018
-- Description:	
	Drop indexes on staging tables related to the RetailerPotentialValue_Monthly report for easier inserting

-- Modification History:
***************************************************************************/

CREATE PROCEDURE [APW].[RetailerPotentialValue_Monthly_Drop_Indexes]

AS 
BEGIN

	SET NOCOUNT ON;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'CIX_RetailerPotentialValue_Monthly_Cardholder') 
	DROP INDEX CIX_RetailerPotentialValue_Monthly_Cardholder ON APW.RetailerPotentialValue_Monthly_Cardholder;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_RetailerPotentialValue_Monthly_Cardholder') 
	DROP INDEX IX_RetailerPotentialValue_Monthly_Cardholder ON APW.RetailerPotentialValue_Monthly_Cardholder;

END