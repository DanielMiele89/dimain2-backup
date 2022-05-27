CREATE TABLE [Staging].[OPE_Customer_Customer_Partner_Exposure] (
    [id]        INT     IDENTITY (1, 1) NOT NULL,
    [FanID]     INT     NULL,
    [PartnerID] INT     NULL,
    [Score]     TINYINT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

