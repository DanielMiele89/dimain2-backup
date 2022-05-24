/******************************************************************************
Author: Jason Shipp
Created: 27/02/2020
Purpose: 
	- Triggers refresh of Warehouse.Relational.Reward3Point0_AccountEarnings table
	- See Relational.Reward3Point0_AccountsEarnings_Load stored procedure
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Relational].[Reward3Point0_AccountsEarnings_Load_Trigger]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	EXEC Relational.Reward3Point0_AccountsEarnings_Load 132, '2020-02-01'; -- Natwest, from 3.0 go live date
	EXEC Relational.Reward3Point0_AccountsEarnings_Load 138, '2020-02-01'; -- RBS, from 3.0 go live date

END