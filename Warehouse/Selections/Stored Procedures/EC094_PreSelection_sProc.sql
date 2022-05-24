-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.EC094_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

-- Move all users into temp table showing their available payment methods

Select cpma.FanID
	 , cpma.PaymentMethodsAvailableID
Into #CPMA
From Warehouse.relational.Customer as c
inner join warehouse.relational.CustomerPaymentMethodsAvailable as cpma
	on c.FanID = cpma.FanID
Where EndDate is null and
	c.CurrentlyActive = 1

/*

Select *
From Warehouse.Relational.PaymentMethodsAvailable

PaymentMethodsAvailableID	Description
0							Debit Card
1							Credit Card
2							Both
3							None

*/


If object_id('Warehouse.Selections.EC_PreSelection_Debit') is not null drop table  Warehouse.Selections.EC_PreSelection_Debit
Select Distinct FanID
Into Warehouse.Selections.EC_PreSelection_Debit
From #CPMA cd
Where PaymentMethodsAvailableID = 0

If object_id('Warehouse.Selections.EC_PreSelection_Credit') is not null drop table  Warehouse.Selections.EC_PreSelection_Credit
Select Distinct FanID
Into Warehouse.Selections.EC_PreSelection_Credit
From #CPMA cd
Where PaymentMethodsAvailableID = 1

If object_id('Warehouse.Selections.EC_PreSelection_DebitCredit') is not null drop table  Warehouse.Selections.EC_PreSelection_DebitCredit
Select Distinct FanID
Into Warehouse.Selections.EC_PreSelection_DebitCredit
From #CPMA cd
Where PaymentMethodsAvailableID = 2

END