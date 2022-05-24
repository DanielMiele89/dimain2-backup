CREATE TABLE [Staging].[RedemptionItem] (
    [RedeemID]                 INT            NOT NULL,
    [RedeemType]               VARCHAR (8)    NULL,
    [PrivateDescription]       NVARCHAR (100) NOT NULL,
    [PartnerID]                INT            NULL,
    [PartnerName]              VARCHAR (100)  NULL,
    [TradeUp_WithValue]        INT            NULL,
    [TradeUp_ClubCashRequired] SMALLMONEY     NULL,
    [TradeUp_Value]            SMALLMONEY     NULL,
    [Status]                   BIT            NULL
);

