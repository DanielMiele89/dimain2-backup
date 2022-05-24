CREATE TABLE [Relational].[PartnerCommissionRates_PostLaunch] (
    [PartnerID]      INT            NOT NULL,
    [PartnerName]    VARCHAR (100)  NULL,
    [CommissionType] VARCHAR (16)   NOT NULL,
    [CommissionRate] NUMERIC (3, 2) NOT NULL,
    [DateAdded]      DATE           NULL,
    [CurrentRate]    INT            NOT NULL,
    [isNonCore]      BIT            NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

