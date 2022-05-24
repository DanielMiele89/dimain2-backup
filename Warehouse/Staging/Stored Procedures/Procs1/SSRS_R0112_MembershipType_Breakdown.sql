--Use Warehouse
/*
	Author:		Stuart Barnley

	Date:		29th December 2015

	Purpose:	To give some information as to the current state of 
				the customer base
				
*/


Create Procedure Staging.SSRS_R0112_MembershipType_Breakdown
as

Select	t.ID as SchememembershipTypeID,
		t.BookType,
		t.AccountType,
		t.CreditCardType,
		t.FreeTrialType,
		Count(*) as Customers
from Relational.Customer as c with (nolock)
inner join [Relational].[Customer_SchemeMembership] as s with (nolock)
	on	c.FanID = s.FanID and
		s.EndDate is null
inner join [Relational].[Customer_SchemeMembershipType] as t with (nolock)
	on	s.SchemeMembershipTypeID = t.ID
Where	c.CurrentlyActive = 1
Group by t.ID,t.BookType,t.AccountType,t.CreditCardType,t.FreeTrialType
Order by t.ID