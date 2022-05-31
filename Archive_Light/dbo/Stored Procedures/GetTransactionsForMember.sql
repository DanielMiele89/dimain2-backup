CREATE proc [dbo].[GetTransactionsForMember] @FanID int
as
set nocount on

declare @CompositeID bigint

select @CompositeID = CompositeID from SLC_Report.dbo.Fan where ID = @FanID

if @CompositeID is null 
	begin
		raiserror ('Member not found',10,1)
		return
	end

select  
	FileID,
	RowNum,
	BankID,
	ClearStatus,
	MerchantID,
	LocationName,
	LocationAddress,
	LocationCountry,
	MCC,
	CardholderPresentData,
	TranDate,
	PostFPInd,
	PostStatus,
	PaymentCardID,
	PanID,
	RetailOutletID,
	IronOfferMemberID,
	MatchID,
	BillingRuleID,
	MarketingRuleID,
	CompositeID,
	MatchStatus,
	FanID,
	RewardStatus,
	Amount
from NobleTransactionHistory where CompositeID = @CompositeID
order by TranDate