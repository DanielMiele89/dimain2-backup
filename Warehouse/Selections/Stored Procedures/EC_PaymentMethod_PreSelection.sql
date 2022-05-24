-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  [Selections].[EC_PaymentMethod_PreSelection]
As
	Begin
--	SET ANSI_WARNINGS OFF;

-- Move all users into temp table showing their available payment methods
	Select cpma.PaymentMethodsAvailableID
		 , cpma.FanID
	Into #CPMA
	From Warehouse.relational.Customer as c
	Left join warehouse.relational.CustomerPaymentMethodsAvailable as cpma
		on c.FanID = cpma.FanID
	Where EndDate is null
	And c.CurrentlyActive = 1

	Create Index IX_CPMA_PaymentMethodFan on #CPMA (PaymentMethodsAvailableID, FanID)

/*

Select *
From Warehouse.Relational.PaymentMethodsAvailable

PaymentMethodsAvailableID	Description
0							Debit Card
1							Credit Card
2							Both
3							None

*/

	If Object_ID('Warehouse.Selections.EC_PreSelection_Debit') Is Not Null Drop Table Warehouse.Selections.EC_PreSelection_Debit
	Select FanID
	Into Warehouse.Selections.EC_PreSelection_Debit
	From #CPMA cd
	Where PaymentMethodsAvailableID = 0

	Create Index IX_ECPreSelectionDebit_Fan on Warehouse.Selections.EC_PreSelection_Debit (FanID)

	If Object_ID('Warehouse.Selections.EC_PreSelection_Credit') Is Not Null Drop Table Warehouse.Selections.EC_PreSelection_Credit
	Select FanID
	Into Warehouse.Selections.EC_PreSelection_Credit
	From #CPMA cd
	Where PaymentMethodsAvailableID = 1

	Create Index IX_ECPreSelectionCredit_Fan on Warehouse.Selections.EC_PreSelection_Credit (FanID)

	If Object_ID('Warehouse.Selections.EC_PreSelection_DebitCredit') Is Not Null Drop Table Warehouse.Selections.EC_PreSelection_DebitCredit
	Select FanID
	Into Warehouse.Selections.EC_PreSelection_DebitCredit
	From #CPMA cd
	Where PaymentMethodsAvailableID = 2

	Create Index IX_ECPreSelectionDebitCredit_Fan on Warehouse.Selections.EC_PreSelection_DebitCredit (FanID)

	If Object_ID('Warehouse.Selections.EC_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC_PreSelection
	Select FanID
	Into Warehouse.Selections.EC_PreSelection
	From Warehouse.Selections.EC_PreSelection_Debit
	Union
	Select FanID
	From Warehouse.Selections.EC_PreSelection_Credit
	Union
	Select FanID
	From Warehouse.Selections.EC_PreSelection_DebitCredit
	
End