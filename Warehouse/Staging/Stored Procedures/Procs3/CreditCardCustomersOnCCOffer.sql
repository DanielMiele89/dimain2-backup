
/********************************************************************************************
	Name: CreditCardCustomerOnOffer
	Desc: Displays the list of CC customers on the CC monthly offers - outputs a list to 
			give to Marketing
	Auth: Zoe Taylor

	Change History
			ZT 2017-12-07
				SP created
	
*********************************************************************************************/


CREATE Procedure Staging.CreditCardCustomersOnCCOffer @RBSOfferID int, @NatwestOfferID int, @RunType bit

As


/******************************************************************		
		Declare variables 
******************************************************************/

Declare @RBSID int
		, @NWID int

Set @RBSID = @RBSOfferID
Set @NWID = @NatwestOfferID
		

/******************************************************************		
		Display offerid's as first check 
******************************************************************/

If @RunType = 0 or @RunType = 1
Begin

	Select *
	From Relational.IronOffer
	where IronOfferID in (@RBSID, @NWID)

End


/******************************************************************		
		Select all CC members on offers
******************************************************************/

If @RunType = 1
Begin

	Select CompositeID
	Into #CCCustomers
	From Relational.IronOfferMember
	Where IronOfferID in (@RBSID, @NWID)

	Create CLUSTERED index idx_CompositeID on #CCCustomers(CompositeID)

	Select c.FanID, c.Email
	Into Sandbox.Zoe.DecemberCCCustomers
	from #CCCustomers cc
	Inner join relational.customer c
		on c.CompositeID = cc.compositeid

End