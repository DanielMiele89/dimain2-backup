CREATE TABLE [Relational].[Customer_MerchantDataMatching] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT  NOT NULL,
    [FanID]     INT  NOT NULL,
    [MatchDate] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_Customer_MerchantDataMatching_PartnerIDFanID]
    ON [Relational].[Customer_MerchantDataMatching]([PartnerID] ASC, [FanID] ASC);

