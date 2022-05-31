CREATE TABLE [Rory].[Charity] (
    [TranID]          INT            NOT NULL,
    [GiftAid]         BIT            NULL,
    [Option]          NVARCHAR (100) NULL,
    [ClubCash]        SMALLMONEY     NULL,
    [FanID]           INT            NOT NULL,
    [CharityDonation] VARCHAR (100)  NULL,
    [RedeemDate]      DATETIME       NOT NULL
);

